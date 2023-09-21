import 'dart:io' as io;
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/widgets/show_message.dart';


void login(void Function() whenFinish) async{
  if(GetPlatform.isWindows && (await FlutterWindowsWebview.isAvailable())){
    var webview = FlutterWindowsWebview();
    webview.launchWebview("https://nhentai.net/login/?next=/", WebviewOptions(
        messageReceiver: (s){
          if(s.substring(0, 2) == "UA"){
            NhentaiNetwork().ua  = s.replaceFirst("UA", "");
          }
        },
        onTitleChange: (title) async{
          if(!title.contains("Login")) {
            webview.runScript("window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
            var cookies = await webview.getCookies("https://nhentai.net");
            await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse("https://nhentai.net"),
                List<io.Cookie>.generate(cookies.length, (index){
                  var cookie = io.Cookie(cookies.keys.elementAt(index), cookies.values.elementAt(index));
                  if(cookie.name == "sessionid"){
                    NhentaiNetwork().logged = true;
                  }
                  cookie.domain = ".nhentai.net";
                  return cookie;
                })
            );
            webview.close();
            whenFinish();
          }
        }
    ));
  } else if(GetPlatform.isMobile) {
    Get.to(() => AppWebview(
      initialUrl: "https://nhentai.net/login/?next=/",
      onTitleChange: (title){
        if (!title.contains("Login")) {
          Get.back();
        }
      },
      onDestroy: (controller) async{
        var ua = await controller.getUA();
        if(ua != null){
          NhentaiNetwork().ua = ua;
        }
        var cookies = await controller.getCookies("https://nhentai.net/") ?? {};
        List<io.Cookie> cookiesList = [];
        cookies.forEach((key, value) {
          var cookie = io.Cookie(key, value);
          if(key == "sessionid"){
            NhentaiNetwork().logged = true;
          }
          cookie.domain = ".nhentai.net";
          cookiesList.add(cookie);
        });
        await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse("https://nhentai.net/"), cookiesList);
        whenFinish();
      },
    ));
  } else {
    showMessage(Get.context, "当前设备不支持".tl);
  }
}
