import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:get/get.dart';

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
      appBar: AppBar(title: Text("登录E-Hentai账户".tr),),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                height: 400,
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("  使用cookie登录".tr,style: const TextStyle(fontSize: 18),),
                    const SizedBox(height: 3,),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c1,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "ipb_member_id"
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c2,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "ipb_pass_hash"
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        controller: c3,
                        decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: "igneous(非必要)".tr
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                        child: !logging?FilledButton(
                          child: Text("登录".tr),
                          onPressed: (){
                            if(c1.text=="" || c2.text==""){
                              showMessage(context, "请填写完整".tr);
                            }else{
                              login(c1.text, c2.text, c3.text);
                            }
                          },
                        ):const CircularProgressIndicator(),
                      ),
                    ),
                    const SizedBox(height: 10,),
                    if(GetPlatform.isAndroid)
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 40,
                          child: TextButton(
                            onPressed: ()async{
                              var browser = LoginInBrowser(() async{
                                CookieManager cookieManager = CookieManager.instance();
                                var id = await cookieManager.getCookie(url: Uri.parse(".e-hentai.org"), name: "ipb_member_id");
                                var hash = await cookieManager.getCookie(url: Uri.parse(".e-hentai.org"), name: "ipb_pass_hash");
                                var igneous = await cookieManager.getCookie(url: Uri.parse(".exhentai.org"), name: "igneous");
                                try {
                                  login(id!.value, hash!.value, igneous==null?"":igneous.value);
                                }
                                catch(e){
                                  showMessage(Get.context, "登录失败".tr);
                                }
                              });
                              await browser.openUrlRequest(urlRequest: URLRequest(url: Uri.parse("https://forums.e-hentai.org/index.php?act=Login&CODE=00")));
                            },
                            child: Row(
                              children: [
                                Text("在Webview中登录".tr),
                                const Icon(Icons.arrow_outward,size: 15,)
                              ],
                            ),
                          ),
                        ),
                      ),
                    if(GetPlatform.isAndroid)
                      const SizedBox(height: 5,),
                    Center(child: SizedBox(
                      width: 68,
                      height: 40,
                      child: TextButton(
                        onPressed: ()=>launchUrlString("https://forums.e-hentai.org/index.php?act=Reg&CODE=00",mode: LaunchMode.externalApplication),
                        child: Row(
                          children: [
                            Text("注册".tr),
                            const Icon(Icons.arrow_outward,size: 15,)
                          ],
                        ),
                      ),
                    ),),
                    SizedBox(
                      width: 400,
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.info_outline,size: 20,),
                          Text("由于需要captcha响应, 暂不支持直接密码登录".tr,maxLines: 2,)
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

  void login(String id, String hash, String igneous){
    setState(() {
      logging = true;
      appdata.ehId = id;
      appdata.ehPassHash = hash;
      appdata.igneous = igneous;
      EhNetwork().getUserName().then((b){
        if(b){
          Get.back();
          showMessage(context, "登录成功".tr);
        }else{
          showMessage(context, EhNetwork().status?EhNetwork().message:"登录失败".tr);
          setState(() {
            logging = false;
          });
        }
      });
    });
  }
}

class LoginInBrowser extends InAppBrowser{
  LoginInBrowser(this.exit);
  final void Function() exit;
  @override
  void onExit() {
    exit();
    super.onExit();
  }
  @override
  void onTitleChanged(String? title) {
    if(title == "E-Hentai Forums"){
      super.close();
    }
    super.onTitleChanged(title);
  }
}