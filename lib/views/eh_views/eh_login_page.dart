import 'package:flutter/material.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../network/eh_network/eh_main_network.dart';

class EhLoginPage extends StatefulWidget {
  const EhLoginPage({Key? key}) : super(key: key);

  @override
  State<EhLoginPage> createState() => _EhLoginPageState();
}

class _EhLoginPageState extends State<EhLoginPage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  bool logging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("登录E-Hentai账户".tl),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "  使用cookie登录".tl,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c1,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "ipb_member_id"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c2,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "ipb_pass_hash"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c3,
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: "igneous(非必要)".tl),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                        child: !logging
                            ? FilledButton(
                                child: Text("登录".tl),
                                onPressed: () {
                                  if (c1.text == "" || c2.text == "") {
                                    showMessage(context, "请填写完整".tl);
                                  } else {
                                    login(c1.text, c2.text, c3.text);
                                  }
                                },
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    if (GetPlatform.isAndroid ||
                        GetPlatform.isWindows ||
                        GetPlatform.isIOS)
                      Center(
                        child: SizedBox(
                          width: 155,
                          height: 40,
                          child: TextButton(
                            onPressed: () async {
                              if (GetPlatform.isAndroid || GetPlatform.isIOS) {
                                loginWithWebview();
                              } else {
                                if (await FlutterWindowsWebview.isAvailable()) {
                                  var webview = FlutterWindowsWebview();
                                  webview.launchWebview(
                                      "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
                                      WebviewOptions(onTitleChange: (s) async {
                                    if (s == "E-Hentai Forums") {
                                      var cookies = await webview
                                          .getCookies("https://e-hentai.org");
                                      var id = cookies["ipb_member_id"];
                                      var hash = cookies["ipb_pass_hash"];
                                      cookies = await webview
                                          .getCookies("https://exhentai.org");
                                      var igneous = cookies["igneous"];
                                      webview.close();
                                      try {
                                        login(id!, hash!, igneous ?? "");
                                      } catch (e) {
                                        LogManager.addLog(LogLevel.error,
                                            "Network", e.toString());
                                        showMessage(Get.context, "登录失败".tl);
                                      }
                                    }
                                  }));
                                } else {
                                  showMessage(Get.context, "Webview不可用");
                                }
                              }
                            },
                            child: Row(
                              children: [
                                Text("在Webview中登录".tl),
                                const Icon(
                                  Icons.arrow_outward,
                                  size: 15,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (GetPlatform.isAndroid || GetPlatform.isIOS)
                      const SizedBox(
                        height: 5,
                      ),
                    Center(
                      child: SizedBox(
                        width: 68,
                        height: 40,
                        child: TextButton(
                          onPressed: () => launchUrlString(
                              "https://forums.e-hentai.org/index.php?act=Reg&CODE=00",
                              mode: LaunchMode.externalApplication),
                          child: Row(
                            children: [
                              Text("注册".tl),
                              const Icon(
                                Icons.arrow_outward,
                                size: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                          ),
                          Text(
                            "由于需要captcha响应, 暂不支持直接密码登录".tl,
                            maxLines: 2,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void login(String id, String hash, String igneous) {
    setState(() {
      logging = true;
      appdata.ehId = id;
      appdata.ehPassHash = hash;
      appdata.igneous = igneous;
      EhNetwork().getUserName().then((b) {
        if (b) {
          Get.back();
          showMessage(context, "登录成功".tl);
        } else {
          showMessage(context, "登录失败".tl);
          setState(() {
            logging = false;
          });
        }
      });
    });
  }

  void loginWithWebview(){
    Get.to(() => AppWebview(
      initialUrl: "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
      onTitleChange: (title){
        if (title == "E-Hentai Forums") {
          Get.back();
        }
      },
      onDestroy: (controller) async{
        var cookies = await controller.getCookies("https://e-hentai.org") ?? {};
        var id = cookies["ipb_member_id"];
        var hash = cookies["ipb_pass_hash"];
        var igneous = cookies["igneous"];
        try {
          login(id!, hash!, igneous ?? "");
        } catch (e) {
          showMessage(Get.context, "登录失败".tl);
        }
      },
    ));

  }
}