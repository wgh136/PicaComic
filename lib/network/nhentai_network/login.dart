import 'dart:io' as io;
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/widgets/show_message.dart';


void login(void Function() whenFinish) async{
  if(NhentaiNetwork().baseUrl.contains("xxx")){
    showMessage(Get.context, "暂不支持");
    return;
  }

  if(GetPlatform.isWindows && (await FlutterWindowsWebview.isAvailable())){
    var webview = FlutterWindowsWebview();
    webview.launchWebview("${NhentaiNetwork().baseUrl}/login/?next=/", WebviewOptions(
        messageReceiver: (s){
          if(s.substring(0, 2) == "UA"){
            NhentaiNetwork().ua  = s.replaceFirst("UA", "");
          }
        },
        onTitleChange: (title) async{
          if(!title.contains("Login") && !title.contains("Register")) {
            webview.runScript("window.chrome.webview.postMessage(\"UA\" + navigator.userAgent)");
            var cookies = await webview.getCookies(NhentaiNetwork().baseUrl);
            await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse(NhentaiNetwork().baseUrl),
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
        }
    ));
  } else if(GetPlatform.isMobile) {
    Get.to(() => AppWebview(
      initialUrl: "${NhentaiNetwork().baseUrl}/login/?next=/",
      singlePage: true,
      onTitleChange: (title){
        if (!title.contains("Login") && !title.contains("Register")) {
          Get.back();
        }
      },
      onDestroy: (controller) async{
        var ua = await controller.getUA();
        if(ua != null){
          NhentaiNetwork().ua = ua;
        }
        var cookies = await controller.getCookies("${NhentaiNetwork().baseUrl}/") ?? {};
        List<io.Cookie> cookiesList = [];
        cookies.forEach((key, value) {
          print("$key : $value");
          var cookie = io.Cookie(key, value);
          if(key == "sessionid" || key == "XSRF-TOKEN"){
            NhentaiNetwork().logged = true;
          }
          cookie.domain = ".nhentai.net";
          cookiesList.add(cookie);
        });
        await NhentaiNetwork().cookieJar!.saveFromResponse(Uri.parse(NhentaiNetwork().baseUrl), cookiesList);
        whenFinish();
      },
    ));
  } else {
    showMessage(Get.context, "当前设备不支持".tl);
  }
}
