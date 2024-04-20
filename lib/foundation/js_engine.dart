import 'dart:convert';
import 'dart:math' as math;

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:flutter_qjs/flutter_qjs.dart';

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

  JsEngine._create() {
    _init();
  }

  FlutterQjs? _engine;

  bool _closed = true;

  Dio? _dio;

  static void reset(){
    _cache = null;
    JsEngine();
  }

  void _init() async{
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
      _engine!.evaluate(_jsInit);
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
    Response<String>? response;
    String? error;

    try {
      var headers = Map<String, dynamic>.from(req["headers"] ?? {});
      if(headers["user-agent"] == null && headers["User-Agent"] == null){
        headers["User-Agent"] = webUA;
      }
      response = switch (req["http_method"]) {
        "GET" =>
        await _dio!.get<String>(
          req["url"],
          options: Options(headers: headers),
        ),
        "POST" =>
        await _dio!.post<String>(
          req["url"],
          data: req["data"],
          options: Options(headers: headers),
        ),
        "PUT" =>
        await _dio!.put<String>(
          req["url"],
          data: req["data"],
          options: Options(headers: headers),
        ),
        "PATCH" =>
        await _dio!.patch<String>(
          req["url"],
          data: req["data"],
          options: Options(headers: headers),
        ),
        "DELETE" =>
        await _dio!.delete<String>(
          req["url"],
          options: Options(headers: headers),
        ),
        _ => throw "Unknown http method: ${req["http_method"]}",
      };
    } catch (e) {
      error = e.toString();
    }

    Map<String, String> headers = {};

    response?.headers.forEach((name, values) => headers[name] = values.join(','));

    return {
      "status": response?.statusCode,
      "headers": headers,
      "body": response?.data,
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

  String _convert(Map<String, dynamic> data) {
    String type = data["type"];
    String value = data["value"];
    bool isEncode = data["isEncode"];
    switch (type) {
      case "base64":
        return isEncode ? base64Encode(utf8.encode(value)) : utf8.decode(base64Decode(value));
      case "md5":
        return isEncode ? md5.convert(utf8.encode(value)).toString() : value;
      default:
        return value;
    }
  }

  int _randomInt(int min, int max) {
    return (min + (max - min) * math.Random().nextDouble()).toInt();
  }
}

const _jsInit = '''
class Convert {
    static encodeBase64(value) {
        return sendMessage({
            method: "convert",
            type: "base64",
            value: value,
            isEncode: true
        });
    }

    static decodeBase64(value) {
        return sendMessage({
            method: "convert",
            type: "base64",
            value: value,
            isEncode: false
        });
    }

    static md5(value) {
        return sendMessage({
            method: "convert",
            type: "md5",
            value: value,
            isEncode: true
        });
    }
}

function randomInt(min, max) {
    return sendMessage({
        method: 'random',
        min: min,
        max: max
    });
}

class _Timer {
    delay = 0;

    callback = () => { };

    status = false;

    constructor(delay, callback) {
        this.delay = delay;
        this.callback = callback;
    }

    run() {
        this.status = true;
        this._interval();
    }

    _interval() {
        if (!this.status) {
            return;
        }
        this.callback();
        setTimeout(this._interval.bind(this), this.delay);
    }

    cancel() {
        this.status = false;
    }
}

function setInterval(callback, delay) {
    let timer = new _Timer(delay, callback);
    timer.run();
    return timer;
}

function Cookie(name, value) {
    let obj = {};
    obj.name = name;
    obj.value = value;
    return obj;
}

class Network {
    /*
        send http request
        ```
        let result = await sendRequest(
            'post', 
            'https://example.com', 
            {
                content-type: 'application/json'
            }, 
            {
                id: '1',
                hash: 'abcdef123'
            },
        )
        ```
    */
    static async sendRequest(method, url, headers, data) {
        let result = await sendMessage({
            method: 'http',
            http_method: method,
            url: url,
            headers: headers,
            data: data
        })

        if(result.error) {
            throw result.error;
        }

        return result;
    }

    /// see [sendRequest]
    static async get(url, headers) {
        return this.sendRequest('GET', url, headers);
    }

    /// see [sendRequest]
    static async post(url, headers, data) {
        return this.sendRequest('POST', url, headers, data);
    }

    /// see [sendRequest]
    static async put(url, headers, data) {
        return this.sendRequest('PUT', url, headers, data);
    }

    /// see [sendRequest]
    static async patch(url, headers, data) {
        return this.sendRequest('PATCH', url, headers, data);
    }

    /// see [sendRequest]
    static async delete(url, headers) {
        return this.sendRequest('DELETE', url, headers);
    }

    /* 
        set cookies
        ```
        setCookies('https://example.com', [
            Cookie('id', '1'),
            Cookie('hash', 'abcdef123')
        ])
        ```
    */
    static setCookies(url, cookies) {
        sendMessage({
            method: 'cookie',
            function: 'set',
            url: url,
            cookies: cookies
        })
    }

    /* 
        get cookies
        ```
        let cookies = getCookies('https://example.com')
        cookies.forEach((cookie) => {
            let name = cookie.name
            let value = cookie.value
        })
        ```
    */
    static getCookies(url) {
        return sendMessage({
            method: 'cookie',
            function: 'get',
            url: url,
        })
    }
}

class HtmlDocument {
    static _key = 0;

    key = 0;

    constructor(html) {
        this.key = HtmlDocument._key;
        HtmlDocument._key++;
        sendMessage({
            method: "html",
            function: "parse",
            key: this.key,
            data: html
        })
    }

    querySelector(query) {
        let k = sendMessage({
            method: "html",
            function: "querySelector",
            key: this.key,
            query: query
        })
        return new HtmlDom(k);
    }

    querySelectorAll(query) {
        let ks = sendMessage({
            method: "html",
            function: "querySelectorAll",
            key: this.key,
            query: query
        })
        return ks.map(k => new HtmlDom(k));
    }
}

class HtmlDom {
    key = 0;

    constructor(k) {
        this.key = k;
    }

    get text() {
        return sendMessage({
            method: "html",
            function: "getText",
            key: this.key
        })
    }

    get attributes() {
        return sendMessage({
            method: "html",
            function: "getAttributes",
            key: this.key
        })
    }

    querySelector(query) {
        let k = sendMessage({
            method: "html",
            function: "dom_querySelector",
            key: this.key,
            query: query
        })
        return new HtmlDom(k);
    }

    querySelectorAll(query) {
        let ks = sendMessage({
            method: "html",
            function: "dom_querySelectorAll",
            key: this.key,
            query: query
        })
        return ks.map(k => new HtmlDom(k));
    }

    get children() {
        let ks = sendMessage({
            method: "html",
            function: "getChildren",
            key: this.key
        })
        return ks.map(k => new HtmlDom(k));
    }
}

function log(level, title, content) {
    sendMessage({
        method: 'log',
        level: level,
        title: title,
        content: content,
    })
}

let console = {
  log: (content) => {
    log('info', 'JS Console', content)
  },
  warn: (content) => {
    log('warning', 'JS Console', content)
  },
  error: (content) => {
    log('error', 'JS Console', content)
  },
};

class ComicSource {
    name = ""

    /// unique identify to this comic source
    key = ""

    version = ""

    minAppVersion = ""

    url = ""

    /*
    load data with its key
    */
    loadData(dataKey) {
        return sendMessage({
            method: 'load_data',
            key: this.key,
            data_key: dataKey
        })
    }

    /*
    save data
    ```
    saveData('id', 1)
    saveData('info', {
        name: '',
        age: 16
    })
    ```
    */
    saveData(dataKey, data) {
        return sendMessage({
            method: 'save_data',
            key: this.key,
            data_key: dataKey,
            data: data
        })
    }

    deleteData(dataKey) {
        return sendMessage({
            method: 'delete_data',
            key: this.key,
            data_key: dataKey,
        })
    }

    init() { }

    static sources = {}
}
''';