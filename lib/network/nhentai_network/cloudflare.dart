import 'dart:io' as io;
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../views/app_views/webview.dart';

Future<void> bypassCloudFlare(void Function() whenFinish) async{
  if(App.isWindows && (await FlutterWindowsWebview.isAvailable())){
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
          whenFinish();
        }
      }
    ));
  } else if(App.isMobile || App.isMacOS) {
    App.globalTo(() => AppWebview(
      initialUrl: "https://nhentai.net",
      singlePage: true,
      onTitleChange: (title, controller) async{
        if (title.contains("nhentai")) {
          var ua = await controller.getUA();
          if(ua != null){
            NhentaiNetwork().ua = ua;
          }
          var cookiesMap = await controller.getCookies("https://nhentai.net/") ?? {};
          var cookies = List<io.Cookie>.generate(cookiesMap.length, (index){
            var cookie = io.Cookie(cookiesMap.keys.elementAt(index), cookiesMap.values.elementAt(index));
            cookie.domain = ".nhentai.net";
            return cookie;
          });
          var current = await NhentaiNetwork().cookieJar!.loadForRequest(Uri.parse("https://nhentai.net"));
          NhentaiNetwork().cookieJar!.deleteAll();
          cookies.addAll(current.where((element) {
            for(var c in cookies){
              if(c.name == element.name){
                return false;
              }
            }
            return true;
          }));
          await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse("https://nhentai.net/"), cookies);
          whenFinish();
          App.globalBack();
        }
      },
    ));
  } else {
    showMessage(App.globalContext, "当前设备不支持".tl);
  }
}
