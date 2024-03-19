import 'dart:io' as io;
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../views/app_views/webview.dart';
import 'jm_network.dart';

Future<void> bypassCloudFlare(void Function() whenFinish) async {
  if (App.isWindows && (await FlutterWindowsWebview.isAvailable())) {
    var webview = FlutterWindowsWebview();
    webview.launchWebview(
        "${JmNetwork.baseUrl}/album/466419",
        WebviewOptions(messageReceiver: (s) {
          if (s.substring(0, 2) == "UA") {
            JmNetwork().ua = s.replaceFirst("UA", "");
          }
        }, onTitleChange: (title) async {
          if (title.contains("禁漫天堂")) {
            webview.runScript(
                "window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
            var cookies = await webview.getCookies(JmNetwork.baseUrl);
            await JmNetwork().cookieJar!.saveFromResponse(
                Uri.parse(JmNetwork.baseUrl),
                List<io.Cookie>.generate(cookies.length, (index) {
                  var cookie = io.Cookie(cookies.keys.elementAt(index),
                      cookies.values.elementAt(index));
                  cookie.domain = ".${Uri.parse(JmNetwork.baseUrl).host}";
                  return cookie;
                }));
            await Future.delayed(const Duration(milliseconds: 100));
            webview.close();
            whenFinish();
          }
        }));
  } else if (App.isMobile || App.isMacOS) {
    App.globalTo(() => AppWebview(
          initialUrl: "${JmNetwork.baseUrl}/album/466419",
          singlePage: true,
          onTitleChange: (title, controller) async{
            if (title.contains("禁漫天堂")) {
              var ua = await controller.getUA();
              if (ua != null) {
                JmNetwork().ua = ua;
              }
              var cookies = await controller.getCookies(JmNetwork.baseUrl) ?? {};
              List<io.Cookie> cookiesList = [];
              cookies.forEach((key, value) {
                var cookie = io.Cookie(key, value);
                cookie.domain = ".${Uri.parse(JmNetwork.baseUrl).host}";
                cookiesList.add(cookie);
              });
              await JmNetwork()
                  .cookieJar!
                  .saveFromResponse(Uri.parse(JmNetwork.baseUrl), cookiesList);
              whenFinish();
              App.globalBack();
            }
          },
        ));
  } else {
    showMessage(App.globalContext, "当前设备不支持".tl);
  }
}
