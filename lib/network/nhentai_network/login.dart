import 'dart:io' as io;
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../http_client.dart';


void login(void Function() whenFinish) async{
  if(NhentaiNetwork().baseUrl.contains("xxx")){
    showMessage(App.globalContext, "暂不支持");
    return;
  }

  if(App.isWindows && (await FlutterWindowsWebview.isAvailable())){
    var webview = FlutterWindowsWebview();
    webview.launchWebview("${NhentaiNetwork().baseUrl}/login/?next=/", WebviewOptions(
        messageReceiver: (s){
          if(s.substring(0, 2) == "UA"){
            NhentaiNetwork().ua  = s.replaceFirst("UA", "");
          }
        },
        onTitleChange: (title) async{
          if(!title.contains("Login") && !title.contains("Register") && title.contains("nhentai")) {
            webview.runScript("window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
            var cookies = await webview.getCookies(NhentaiNetwork().baseUrl);
            NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse(NhentaiNetwork().baseUrl),
                List<io.Cookie>.generate(cookies.length, (index){
                  var cookie = io.Cookie(cookies.keys.elementAt(index), cookies.values.elementAt(index));
                  if(cookie.name == "sessionid"){
                    NhentaiNetwork().logged = true;
                  }
                  cookie.domain = NhentaiNetwork().baseUrl.replaceAll("https://", ".");
                  return cookie;
                })
            );
            webview.close();
            whenFinish();
          }
        },
        proxy: proxyHttpOverrides?.proxyStr,
    ));
  } else if(App.isMacOS) {
    var webview = MacWebview(
        onTitleChange: (title, controller, browser) async{
          if(title == null) return;
          if(!title.contains("Login") && !title.contains("Register") && title.contains("nhentai")) {
            var ua = await controller.getUA();
            if(ua != null){
              NhentaiNetwork().ua = ua;
            }
            var cookiesMap = await controller.getCookies("${NhentaiNetwork().baseUrl}/") ?? {};
            NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse(NhentaiNetwork().baseUrl),
                List<io.Cookie>.generate(cookiesMap.length, (index){
                  var cookie = io.Cookie(cookiesMap.keys.elementAt(index), cookiesMap.values.elementAt(index));
                  if(cookie.name == "sessionid"){
                    NhentaiNetwork().logged = true;
                  }
                  cookie.domain = ".nhentai.net";
                  return cookie;
                })
            );
            browser.close();
            whenFinish();
          }
        }
    );
    await webview.openUrlRequest(
      urlRequest: URLRequest(url: WebUri("${NhentaiNetwork().baseUrl}/login/?next=/")),
    );
  } else if(App.isMobile) {
    App.globalTo(() => AppWebview(
      initialUrl: "${NhentaiNetwork().baseUrl}/login/?next=/",
      singlePage: true,
      onTitleChange: (title, controller) async{
        if (!title.contains("Login") && !title.contains("Register") && title.contains("nhentai")) {
          var ua = await controller.getUA();
          if(ua != null){
            NhentaiNetwork().ua = ua;
          }
          var cookies = await controller.getCookies("${NhentaiNetwork().baseUrl}/") ?? {};
          List<io.Cookie> cookiesList = [];
          cookies.forEach((key, value) {
            var cookie = io.Cookie(key, value);
            if(key == "sessionid" || key == "XSRF-TOKEN"){
              NhentaiNetwork().logged = true;
            }
            cookie.domain = ".nhentai.net";
            cookiesList.add(cookie);
          });
          NhentaiNetwork().cookieJar!.saveFromResponse(
              Uri.parse(NhentaiNetwork().baseUrl), cookiesList);
          whenFinish();
          App.globalBack();
        }
      },
    ));
  } else {
    showMessage(App.globalContext, "当前设备不支持".tl);
  }
}
