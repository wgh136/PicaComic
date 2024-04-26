import 'dart:convert';
import 'dart:math' as math;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/block/modes/cfb.dart';
import 'package:pointycastle/block/modes/ecb.dart';
import 'package:pointycastle/block/modes/ofb.dart';


class JavaScriptRuntimeException implements Exception {
  final String message;

  JavaScriptRuntimeException(this.message);

  @override
  String toString() {
    return "JSException: $message";
  }
}

class JsEngine with _JSEngineApi{
  factory JsEngine() => _cache ?? (_cache = JsEngine._create());

  static JsEngine? _cache;

  JsEngine._create();

  FlutterQjs? _engine;

  bool _closed = true;

  Dio? _dio;

  static void reset(){
    _cache = null;
    _cache?.dispose();
    JsEngine().init();
  }

  Future<void> init() async{
    if (!_closed) {
      return;
    }
    try {
      _dio ??= logDio(BaseOptions(
          responseType: ResponseType.plain, validateStatus: (status) => true));
      _cookieJar ??= SingleInstanceCookieJar.instance!;
      _dio!.interceptors.add(CookieManagerSql(_cookieJar!));
      _closed = false;
      _engine = FlutterQjs();
      _engine!.dispatch();
      var setGlobalFunc = _engine!.evaluate(
          "(key, value) => { this[key] = value; }");
      (setGlobalFunc as JSInvokable)(["sendMessage", _messageReceiver]);
      setGlobalFunc.free();
      var jsInit = await rootBundle.load("assets/init.js");
      _engine!.evaluate(utf8.decode(jsInit.buffer.asUint8List()));
    }
    catch(e, s){
      log('JS Engine Init Error:\n$e\n$s', 'JS Engine', LogLevel.error);
    }
  }

  dynamic _messageReceiver(dynamic message) {
    try {
      if (message is Map<dynamic, dynamic>) {
        String method = message["method"] as String;
        switch (method) {
          case "log":
            {
              String level = message["level"];
              LogManager.addLog(
                  switch (level) {
                    "error" => LogLevel.error,
                    "warning" => LogLevel.warning,
                    "info" => LogLevel.info,
                    _ => LogLevel.warning
                  },
                  message["title"],
                  message["content"]);
            }
          case 'load_data':
            {
              String key = message["key"];
              String dataKey = message["data_key"];
              return ComicSource.sources
                  .firstWhereOrNull((element) => element.key == key)
                  ?.data[dataKey];
            }
          case 'save_data':
            {
              String key = message["key"];
              String dataKey = message["data_key"];
              var data = message["data"];
              var source = ComicSource.sources
                  .firstWhere((element) => element.key == key);
              source.data[dataKey] = data;
              source.saveData();
            }
          case 'delete_data':
            {
              String key = message["key"];
              String dataKey = message["data_key"];
              var source = ComicSource.sources
                  .firstWhereOrNull((element) => element.key == key);
              source?.data.remove(dataKey);
              source?.saveData();
            }
          case 'http':
            {
              return _http(Map.from(message));
            }
          case 'html':
            {
              return handleHtmlCallback(Map.from(message));
            }
          case 'convert':
            {
              return _convert(Map.from(message));
            }
          case "random":
            {
              return _randomInt(message["min"], message["max"]);
            }
          case "cookie":
            {
              return handleCookieCallback(Map.from(message));
            }
        }
      }
    }
    catch(e, s){
      log("Failed to handle message: $message\n$e\n$s", "JsEngine", LogLevel.error);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _http(Map<String, dynamic> req) async{
    Response? response;
    String? error;

    try {
      var headers = Map<String, dynamic>.from(req["headers"] ?? {});
      if(headers["user-agent"] == null && headers["User-Agent"] == null){
        headers["User-Agent"] = webUA;
      }
      response = await _dio!.request(req["url"], data: req["data"], options: Options(
        method: req['http_method'],
        responseType: req["bytes"] == true ? ResponseType.bytes : ResponseType.plain,
        headers: headers
      ));
    } catch (e) {
      error = e.toString();
    }

    Map<String, String> headers = {};

    response?.headers.forEach((name, values) => headers[name] = values.join(','));

    dynamic body = response?.data;
    if(body is! Uint8List && body is List<int>) {
      body = Uint8List.fromList(body);
    }

    return {
      "status": response?.statusCode,
      "headers": headers,
      "body": body,
      "error": error,
    };
  }

  dynamic runCode(String js, [String? name]) {
    return _engine!.evaluate(js, name: name);
  }

  void dispose() {
    _cache = null;
    _closed = true;
    _engine?.close();
    _engine?.port.close();
  }
}

mixin class _JSEngineApi{
  final Map<int, dom.Document> _documents = {};
  final Map<int, dom.Element> _elements = {};
  CookieJarSql? _cookieJar;

  dynamic handleHtmlCallback(Map<String, dynamic> data) {
    switch (data["function"]) {
      case "parse":
        _documents[data["key"]] = html.parse(data["data"]);
        return null;
      case "querySelector":
        var res = _documents[data["key"]]!.querySelector(data["query"]);
        if(res == null) return null;
        _elements[_elements.length] = res;
        return _elements.length - 1;
      case "querySelectorAll":
        var res = _documents[data["key"]]!.querySelectorAll(data["query"]);
        var keys = <int>[];
        for(var element in res){
          _elements[_elements.length] = element;
          keys.add(_elements.length - 1);
        }
        return keys;
      case "getText":
        return _elements[data["key"]]!.text;
      case "getAttributes":
        return _elements[data["key"]]!.attributes;
      case "dom_querySelector":
        var res = _elements[data["key"]]!.querySelector(data["query"]);
        if(res == null) return null;
        _elements[_elements.length] = res;
        return _elements.length - 1;
      case "dom_querySelectorAll":
        var res = _elements[data["key"]]!.querySelectorAll(data["query"]);
        var keys = <int>[];
        for(var element in res){
          _elements[_elements.length] = element;
          keys.add(_elements.length - 1);
        }
        return keys;
      case "children":
        var res = _elements[data["key"]]!.children;
        var keys = <int>[];
        for(var element in res){
          _elements[_elements.length] = element;
          keys.add(_elements.length - 1);
        }
        return keys;
    }
  }

  dynamic handleCookieCallback(Map<String, dynamic> data) {
    switch (data["function"]) {
      case "set":
        _cookieJar!.saveFromResponse(
            Uri.parse(data["url"]),
            (data["cookies"] as List).map(
                    (e) => Cookie(e["name"], e["value"])).toList());
        return null;
      case "get":
        var cookies = _cookieJar!.loadForRequest(Uri.parse(data["url"]));
        return cookies.map((e) => {
          "name": e.name,
          "value": e.value,
          "domain": e.domain,
          "path": e.path,
          "expires": e.expires,
          "max-age": e.maxAge,
          "secure": e.secure,
          "httpOnly": e.httpOnly,
          "session": e.expires == null,
        }).toList();
      case "delete":
        clearCookies([data["url"]]);
        return null;
    }
  }

  void clear(){
    _documents.clear();
    _elements.clear();
  }

  void clearCookies(List<String> domains) async{
    for(var domain in domains){
      var uri = Uri.tryParse(domain);
      if(uri == null) continue;
      _cookieJar!.deleteUri(uri);
    }
  }

  dynamic _convert(Map<String, dynamic> data) {
    String type = data["type"];
    var value = data["value"];
    bool isEncode = data["isEncode"];
    switch (type) {
      case "base64":
        if(value is String){
          value = utf8.encode(value);
        }
        return isEncode
            ? base64Encode(value)
            : base64Decode(value);
      case "md5":
        return Uint8List.fromList(md5.convert(value).bytes);
      case "sha1":
        return Uint8List.fromList(sha1.convert(value).bytes);
      case "sha256":
        return Uint8List.fromList(sha256.convert(value).bytes);
      case "sha512":
        return Uint8List.fromList(sha512.convert(value).bytes);
      case "aes-ecb":
        if(!isEncode){
          var key = data["key"];
          var cipher = ECBBlockCipher(AESEngine());
          cipher.init(false, KeyParameter(key));
          return cipher.process(value);
        }
        return null;
      case "aes-cbc":
        if(!isEncode){
          var key = data["key"];
          var iv = data["iv"];
          var cipher = CBCBlockCipher(AESEngine());
          cipher.init(false, ParametersWithIV(KeyParameter(key), iv));
          return cipher.process(value);
        }
        return null;
      case "aes-cfb":
        if(!isEncode){
          var key = data["key"];
          var blockSize = data["blockSize"];
          var cipher = CFBBlockCipher(AESEngine(), blockSize);
          cipher.init(false, KeyParameter(key));
          return cipher.process(value);
        }
        return null;
      case "aes-ofb":
        if(!isEncode){
          var key = data["key"];
          var blockSize = data["blockSize"];
          var cipher = OFBBlockCipher(AESEngine(), blockSize);
          cipher.init(false, KeyParameter(key));
          return cipher.process(value);
        }
        return null;
      case "rsa":
        if(!isEncode){
          var key = data["key"];
          var cipher = RSAEngine()
            ..init(false, PublicKeyParameter<RSAPublicKey>(key));
          return cipher.process(value);
        }
        return null;
      default:
        return value;
    }
  }

  int _randomInt(int min, int max) {
    return (min + (max - min) * math.Random().nextDouble()).toInt();
  }
}
