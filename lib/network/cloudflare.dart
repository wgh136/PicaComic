import 'dart:async';
import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/pages/webview.dart';
import 'package:pica_comic/tools/translations.dart';

import '../components/components.dart';
import 'http_client.dart';

class CloudflareException implements DioException {
  final String url;

  const CloudflareException(this.url);

  @override
  String toString() {
    return "CloudflareException: $url";
  }

  static CloudflareException? fromString(String message) {
    var match = RegExp(r"CloudflareException: (.+)").firstMatch(message);
    if (match == null) return null;
    return CloudflareException(match.group(1)!);
  }

  @override
  DioException copyWith(
      {RequestOptions? requestOptions,
      Response<dynamic>? response,
      DioExceptionType? type,
      Object? error,
      StackTrace? stackTrace,
      String? message}) {
    return this;
  }

  @override
  Object? get error => this;

  @override
  String? get message => toString();

  @override
  RequestOptions get requestOptions => RequestOptions();

  @override
  Response? get response => null;

  @override
  StackTrace get stackTrace => StackTrace.empty;

  @override
  DioExceptionType get type => DioExceptionType.badResponse;
}

class CloudflareInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if(options.headers['cookie'].toString().contains('cf_clearance')) {
      options.headers['user-agent'] = appdata.implicitData[3];
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 403) {
      handler.next(_check(err.response!) ?? err);
    } else {
      handler.next(err);
    }
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 403) {
      var err = _check(response);
      if (err != null) {
        handler.reject(err);
        return;
      }
    }
    handler.next(response);
  }

  CloudflareException? _check(Response response) {
    if (response.headers['cf-mitigated']?.firstOrNull == "challenge") {
      return CloudflareException(response.requestOptions.uri.toString());
    }
    return null;
  }
}

void passCloudflare(CloudflareException e, void Function() onFinished) async {
  var url = e.url;
  var uri = Uri.parse(url);

  void saveCookies(Map<String, String> cookies) {
    var domain = uri.host;
    var splits = domain.split('.');
    if (splits.length > 1) {
      domain = ".${splits[splits.length - 2]}.${splits[splits.length - 1]}";
    }
    SingleInstanceCookieJar.instance!.saveFromResponse(
      uri,
      List<io.Cookie>.generate(cookies.length, (index) {
        var cookie = io.Cookie(
            cookies.keys.elementAt(index), cookies.values.elementAt(index));
        cookie.domain = domain;
        return cookie;
      }),
    );
  }

  if (App.isWindows && (await FlutterWindowsWebview.isAvailable())) {
    var webview = FlutterWindowsWebview();
    Completer<bool>? pass;
    webview.launchWebview(
      url,
      WebviewOptions(
        messageReceiver: (s) {
          if (s.substring(0, 2) == "UA") {
            appdata.implicitData[3] = s.replaceFirst("UA", "");
            appdata.writeImplicitData();
          } else if (s == "challenge passed") {
            pass?.complete(true);
          } else if (s == "challenge failed") {
            pass?.complete(false);
          }
        },
        onTitleChange: (title) async {
          pass = Completer();
          webview.runScript(
              "window.chrome.webview.postMessage(document.head.innerHTML.includes('#challenge-success-text') ? 'challenge failed' : 'challenge passed')");
          if (await pass!.future) {
            webview.runScript(
                "window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
            var cookies = await webview.getCookies(url);
            if(cookies['cf_clearance'] == null) {
              return;
            }
            saveCookies(cookies);
            webview.close();
            onFinished();
          }
        },
        proxy: proxyHttpOverrides?.proxyStr,
      ),
    );
  } else if (App.isMacOS) {
    var webview = MacWebview(
      onStarted: (controller, browser) async {
        var ua = await controller.getUA();
        if (ua != null) {
          appdata.implicitData[3] = ua;
          appdata.writeImplicitData();
        }
        var cookiesMap = await controller.getCookies(url) ?? {};
        saveCookies(cookiesMap);
      },
      onTitleChange: (title, controller, browser) async {
        var res = await controller.platform.evaluateJavascript(
            source:
                "document.head.innerHTML.includes('#challenge-success-text')");
        if (res == false) {
          var ua = await controller.getUA();
          if (ua != null) {
            appdata.implicitData[3] = ua;
            appdata.writeImplicitData();
          }
          var cookiesMap = await controller.getCookies(url) ?? {};
          if(cookiesMap['cf_clearance'] == null) {
            return;
          }
          saveCookies(cookiesMap);
          browser.close();
        }
      },
      onClose: () {
        onFinished();
      },
    );
    await webview.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  } else if (App.isMobile) {
    await App.globalTo(
      () => AppWebview(
        initialUrl: url,
        singlePage: true,
        onTitleChange: (title, controller) async {
          var res = await controller.platform.evaluateJavascript(
              source:
                  "document.head.innerHTML.includes('#challenge-success-text')");
          if (res == false) {
            var ua = await controller.getUA();
            if (ua != null) {
              appdata.implicitData[3] = ua;
              appdata.writeImplicitData();
            }
            var cookiesMap = await controller.getCookies(url) ?? {};
            if(cookiesMap['cf_clearance'] == null) {
              return;
            }
            saveCookies(cookiesMap);
            App.globalBack();
          }
        },
        onStarted: (controller) async {
          var ua = await controller.getUA();
          if (ua != null) {
            appdata.implicitData[3] = ua;
            appdata.writeImplicitData();
          }
          var cookiesMap = await controller.getCookies(url) ?? {};
          saveCookies(cookiesMap);
        },
      ),
    );
    onFinished();
  } else {
    showToast(message: "当前设备不支持".tl);
  }
}
