import 'dart:io' as io;

import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/pages/webview.dart';
import 'package:pica_comic/tools/translations.dart';


void nhLogin(void Function() onFinished) async{
  if(NhentaiNetwork().baseUrl.contains("xxx")){
    showToast(message: "暂不支持");
    return;
  }

  if(App.isDesktop && (await DesktopWebview.isAvailable())){
    var webview = DesktopWebview(
      initialUrl: "${NhentaiNetwork().baseUrl}/login/?next=/",
      onTitleChange: (title, controller) async{
        if(title == "nhentai.net")  return;
        if (!title.contains("Login") && !title.contains("Register") && title.contains("nhentai")) {
          var ua = controller.userAgent;
          if(ua != null){
            appdata.implicitData[3] = ua;
            appdata.writeImplicitData();
          }
          var cookies = await controller.getCookies("${NhentaiNetwork().baseUrl}/");
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
          onFinished();
          controller.close();
        }
      },
    );
    webview.open();
  } else if(App.isMobile) {
    App.globalTo(() => AppWebview(
      initialUrl: "${NhentaiNetwork().baseUrl}/login/?next=/",
      singlePage: true,
      onTitleChange: (title, controller) async{
        if (!title.contains("Login") && !title.contains("Register") && title.contains("nhentai")) {
          var ua = await controller.getUA();
          if(ua != null){
            appdata.implicitData[3] = ua;
            appdata.writeImplicitData();
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
          onFinished();
          App.globalBack();
        }
      },
    ));
  } else {
    showToast(message: "当前设备不支持".tl);
  }
}
