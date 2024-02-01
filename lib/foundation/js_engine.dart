import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_js/extensions/xhr.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';

class JsEngine {
  factory JsEngine() => _cache ?? (_cache = JsEngine._create());

  static JsEngine? _cache;

  JsEngine._create() {
    _init();
  }

  JavascriptRuntime? _jsRuntime;

  bool _closed = true;

  Dio? _dio;

  int _messageKey = 0;

  final Map<int, dynamic> _responseData = {};

  void _init() {
    if (!_closed) {
      return;
    }
    _closed = false;
    _jsRuntime = getJavascriptRuntime(xhr: false);
    _jsRuntime!.onMessage("message", _messageReceiver);
    _jsRuntime!.evaluate('''
class Network {
    static async sendRequest(method, url, headers, data) {
        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();

            xhr.open(method, url, true);

            if (headers) {
                for (const [key, value] of Object.entries(headers)) {
                    xhr.setRequestHeader(key, value);
                }
            }

            xhr.onreadystatechange = function () {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status >= 200 && xhr.status < 300) {
                        resolve(xhr.responseText);
                    } else {
                        reject(new Error(`Request failed with status \${xhr.status}`));
                    }
                }
            };

            const requestBody = JSON.stringify(data);

            xhr.send(requestBody);
        });
    }

    static async get(url, headers) {
        return this.sendRequest('GET', url, headers);
    }

    static async post(url, headers, data) {
        return this.sendRequest('POST', url, headers, data);
    }

    static async put(url, headers, data) {
        return this.sendRequest('PUT', url, headers, data);
    }

    static async patch(url, headers, data) {
        return this.sendRequest('PATCH', url, headers, data);
    }
}

function log(level, title, content){
    sendMessage('message', JSON.stringify({
        method: 'log',
        level: level,
        title: title,
        content: content,
    }))
}

function loadData(key, dataKey){
  return sendMessage('message', JSON.stringify({
    method: 'load_data',
    key: key,
    data_key: dataKey,
  }));
}

function saveData(key, dataKey, data){
  return sendMessage('message', JSON.stringify({
    method: 'save_data',
    key: key,
    data_key: dataKey,
    data: data
  }));
}

let tempData = {}
    ''');
    _loop();
  }

  dynamic _messageReceiver(dynamic message) {
    if (message is Map) {
      String method = message["method"];
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
        case 'return':
          {
            int key = message["key"];
            _responseData[key] = message["data"];
            Future.delayed(
                const Duration(seconds: 20), () => _responseData[key] = null);
          }
        case 'load_data':
          {
            String key = message["key"];
            String dataKey = message["data_key"];
            return ComicSource.sources
                .firstWhere((element) => element.key == key)
                .data[dataKey];
          }

        case 'save_data':
          {
            String key = message["key"];
            String dataKey = message["data_key"];
            String data = message["data"];
            var source = ComicSource.sources
                .firstWhere((element) => element.key == key);
            source.data[dataKey] = data;
            source.saveData();
          }
      }
    }
  }

  void _loop() async {
    _jsRuntime!.dartContext[XHR_PENDING_CALLS_KEY] = [];

    _dio ??= logDio(BaseOptions(
        responseType: ResponseType.plain, validateStatus: (status) => true));

    _jsRuntime!.evaluate("""
    var xhrRequests = {};
    var idRequest = -1;
    function XMLHttpRequestExtension_send_native() {
      idRequest += 1;
      var cb = arguments[4];
      var context = arguments[5];
      xhrRequests[idRequest] = {
        callback: function(responseInfo, responseText, error) {
          cb(responseInfo, responseText, error);
        }
      };
      var args = [];
      args[0] = arguments[0];
      args[1] = arguments[1];
      args[2] = arguments[2];
      args[3] = arguments[3];
      args[4] = idRequest;
      sendMessage('SendNative', JSON.stringify(args));
    }
    """);

    _jsRuntime!.evaluate(xhrJsCode);

    _jsRuntime!.onMessage('SendNative', (arguments) {
      try {
        String? method = arguments[0];
        String? url = arguments[1];
        dynamic headersList = arguments[2];
        String? body = arguments[3];
        int? idRequest = arguments[4];

        Map<String, String> headers = {};
        headersList.forEach((header) {
          String headerKey = header[0];
          headers[headerKey] = header[1];
        });
        (_jsRuntime!.dartContext[XHR_PENDING_CALLS_KEY] as List<dynamic>).add(
          XhrPendingCall(
            idRequest: idRequest,
            method: method,
            url: url,
            headers: headers,
            body: body,
          ),
        );
      } catch (e) {
        //
      }
    });

    while (_jsRuntime != null) {
      if (_closed) return;

      _jsRuntime!.executePendingJob();

      var requests = _jsRuntime!.getPendingXhrCalls();

      if (requests != null) {
        requests = List.from(requests);
        _jsRuntime!.clearXhrPendingCalls();
        for (XhrPendingCall req in requests) {
          Future.sync(() async {
            HttpMethod eMethod = HttpMethod.values.firstWhere((e) =>
                e.toString().toLowerCase() ==
                ("HttpMethod.${req.method}".toLowerCase()));

            Response<String>? response;
            String? error;

            try {
              response = switch (eMethod) {
                HttpMethod.head => await _dio!.head<String>(
                    req.url!,
                    options: Options(headers: req.headers),
                  ),
                HttpMethod.get => await _dio!.get<String>(
                    req.url!,
                    options: Options(headers: req.headers),
                  ),
                HttpMethod.post => await _dio!.post<String>(
                    req.url!,
                    data: req.body,
                    options: Options(headers: req.headers),
                  ),
                HttpMethod.put => await _dio!.put<String>(
                    req.url!,
                    data: req.body,
                    options: Options(headers: req.headers),
                  ),
                HttpMethod.patch => await _dio!.patch<String>(
                    req.url!,
                    data: req.body,
                    options: Options(headers: req.headers),
                  ),
                HttpMethod.delete => await _dio!.delete<String>(
                    req.url!,
                    options: Options(headers: req.headers),
                  )
              };
            } catch (e) {
              error = e.toString();
            }

            String? responseText = response?.data;
            final xhrResult = XmlHttpRequestResponse(
                responseText: responseText,
                responseInfo:
                    XhtmlHttpResponseInfo(statusCode: response?.statusCode),
                error: error);

            final responseInfo = jsonEncode(xhrResult.responseInfo);

            _jsRuntime?.evaluate(
              "globalThis.xhrRequests[${req.idRequest}].callback($responseInfo, `$responseText`, $error);",
            );
          });
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  void runCode(String js) {
    var res = _jsRuntime!.evaluate(js);

    if (res.isError) {
      throw res.rawResult;
    }
  }

  void runProtected(String js) {
    var res = _jsRuntime!.evaluate('''
      function pica_protected_zone(){
        $js
      }
      pica_protected_zone();
    ''');

    if (res.isError) {
      throw res.rawResult;
    }
  }

  Future<int> runProtectedWithKey(String js) async {
    _messageKey++;

    var res = await _jsRuntime!.evaluateAsync('''
      function pica_protected_zone(){
        function success(data){
          sendMessage('message', JSON.stringify({
            method: 'return',
            data: data,
            key: $_messageKey,
          }));
        }
        $js
      }
      pica_protected_zone();
    ''');

    if (res.isError) {
      throw res.rawResult;
    }

    return _messageKey;
  }

  void dispose() {
    _cache = null;
    _closed = true;
    _jsRuntime!.dispose();
  }

  Future<dynamic> wait(int key) async {
    for (int i = 0; i < 20; i++) {
      if (_responseData[key] != null) {
        return _responseData[key];
      }
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}
