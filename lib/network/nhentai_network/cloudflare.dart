import 'dart:io' as io;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

Future<void> bypassCloudFlare(void Function() whenFinish) async{
  if(GetPlatform.isWindows && (await FlutterWindowsWebview.isAvailable())){
    var webview = FlutterWindowsWebview();
    webview.launchWebview("https://nhentai.net", WebviewOptions(
      messageReceiver: (s){
        if(s.substring(0, 2) == "UA"){
          NhentaiNetwork().ua  = s.replaceFirst("UA", "");
        }
      },
      onTitleChange: (title) async{
        if(title.contains("nhentai")) {
          webview.runScript("window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
          var cookies = await webview.getCookies("https://nhentai.net");
          await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse("https://nhentai.net"),
              List<io.Cookie>.generate(cookies.length, (index){
                var cookie = io.Cookie(cookies.keys.elementAt(index), cookies.values.elementAt(index));
                cookie.domain = ".nhentai.net";
                return cookie;
              })
          );
          webview.close();
        }
      }
    ));
  } else if(GetPlatform.isMobile) {
    var browser = ByPassCloudflare(() async {
      CookieManager cookieManager = CookieManager.instance();
      var cookies = await cookieManager.getCookies(url: WebUri("https://nhentai.net"),);
      await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse("https://nhentai.net"),
          List<io.Cookie>.generate(cookies.length, (index){
            var cookie = io.Cookie(cookies[index].name, cookies[index].value);
            cookie.domain = ".nhentai.net";
            return cookie;
          })
      );
    });
    await browser.openUrlRequest(
        urlRequest: URLRequest(
            url: WebUri(
                "https://nhentai.net")));
  } else {
    showMessage(Get.context, "当前设备不支持".tl);
  }

  whenFinish();
}

class ByPassCloudflare extends InAppBrowser {
  ByPassCloudflare(this.action);
  final Future<void> Function() action;

  @override
  void onTitleChanged(String? title) async{
    if (title?.contains("nhentai") ?? false) {
      var res = await webViewController?.evaluateJavascript(source: "navigator.userAgent");
      NhentaiNetwork().ua = res.toString();
      await action();
      super.close();
    }
  }
}
