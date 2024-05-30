import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';
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
  final c4 = TextEditingController();
  bool logging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("登录".tl),
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
                      "  Cookies".tl,
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
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c4,
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: "star(非必要)".tl),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                        child: !logging
                            ? FilledButton(
                                child: Text("登录".tl),
                                onPressed: () {
                                  if (c1.text == "" || c2.text == "") {
                                    showMessage(context, "请填写完整".tl);
                                  } else {
                                    login(c1.text, c2.text, c3.text, c4.text);
                                  }
                                },
                              )
                            : const CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: loginWithWebview,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: SizedBox(
                        height: 40,
                        child: TextButton(
                          onPressed: () => launchUrlString(
                              "https://forums.e-hentai.org/index.php?act=Reg&CODE=00",
                              mode: LaunchMode.externalApplication),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void loginWithWebview() async {
    if (App.isMobile) {
      App.globalTo(() => AppWebview(
            singlePage: true,
            initialUrl:
                "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
            onTitleChange: (title, controller) async {
              if (title == "E-Hentai Forums") {
                var cookies1 =
                    await controller.getCookies("https://e-hentai.org") ?? {};
                var cookies2 =
                    await controller.getCookies("https://exhentai.org") ?? {};
                var cookies = <String, String>{};
                cookies1.forEach((key, value) {
                  cookies[key] = value;
                });
                cookies2.forEach((key, value) {
                  cookies[key] = value;
                });
                loginWithCookies(cookies);
                App.globalBack();
              }
            },
          ));
    } else if (App.isWindows) {
      if (await FlutterWindowsWebview.isAvailable()) {
        var webview = FlutterWindowsWebview();
        webview.launchWebview(
            "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
            WebviewOptions(onTitleChange: (s) async {
          if (s == "E-Hentai Forums") {
            var cookies1 = await webview.getCookies("https://e-hentai.org");
            var cookies2 = await webview.getCookies("https://exhentai.org");
            webview.close();
            var cookies = <String, String>{};
            cookies1.forEach((key, value) {
              cookies[key] = value;
            });
            cookies2.forEach((key, value) {
              cookies[key] = value;
            });
            loginWithCookies(cookies);
          }
        }));
      } else if (App.isMacOS) {
        var webview =
            MacWebview(onTitleChange: (title, controller, browser) async {
          if (title == "E-Hentai Forums") {
            var cookies1 =
                await controller.getCookies("https://e-hentai.org") ?? {};
            var cookies2 =
                await controller.getCookies("https://exhentai.org") ?? {};
            var cookies = <String, String>{};
            cookies1.forEach((key, value) {
              cookies[key] = value;
            });
            cookies2.forEach((key, value) {
              cookies[key] = value;
            });
            loginWithCookies(cookies);
            browser.close();
          }
        });
        await webview.openUrlRequest(
          urlRequest: URLRequest(url: WebUri("https://nhentai.net")),
        );
      } else {
        showMessage(App.globalContext, "Unsupported device".tl);
      }
    }
  }

  void login(String id, String hash, String igneous, String star) {
    loginWithCookies({
      "ipb_member_id": id,
      "ipb_pass_hash": hash,
      if (igneous != "") "igneous": igneous,
      if (star != "") "star": star,
    });
  }

  void loginWithCookies(Map<String, String> cookiesMap) async {
    setState(() {
      logging = true;
    });

    EhNetwork().cookieJar.deleteUri(Uri.parse('https://e-hentai.org'));
    EhNetwork().cookieJar.deleteUri(Uri.parse('https://exhentai.org'));

    var cookies =
        cookiesMap.entries.map((e) => Cookie(e.key, e.value)).toList();
    cookies.forEach((element) => element.domain = ".e-hentai.org");
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://e-hentai.org"), cookies);
    cookies.forEach((element) => element.domain = ".exhentai.org");
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://exhentai.org"), cookies);

    EhNetwork().getUserName().then((b) {
      if (b) {
        App.back(context);
        showMessage(context, "登录成功".tl);
      } else {
        EhNetwork().cookieJar.deleteUri(Uri.parse('https://e-hentai.org'));
        EhNetwork().cookieJar.deleteUri(Uri.parse('https://exhentai.org'));
        showMessage(context, "登录失败".tl);
        setState(() {
          logging = false;
        });
      }
    });
  }
}
