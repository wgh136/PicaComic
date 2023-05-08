import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:get/get.dart';

import '../../eh_network/eh_main_network.dart';

class EhLoginPage extends StatefulWidget {
  const EhLoginPage({Key? key}) : super(key: key);

  @override
  State<EhLoginPage> createState() => _EhLoginPageState();
}

class _EhLoginPageState extends State<EhLoginPage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  bool logging = false;

  @override
  Widget build(BuildContext context) {
    double padding = MediaQuery.of(context).size.width>600?MediaQuery.of(context).size.width-600:0;
    return Scaffold(
      appBar: AppBar(title: const Text("登录E-Hentai账户"),),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding/2, 0, padding/2, 0),
          child: Column(
            children: [
              const Text("  使用cookie登录",style: TextStyle(fontSize: 16),),
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: !logging?FilledButton(
                    child: const Text("登录"),
                    onPressed: (){
                      if(c1.text==""||c2.text==""){
                        showMessage(context, "请填写完整");
                      }else{
                        login(c1.text,c2.text);
                      }
                    },
                  ):const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 10,),
              if(GetPlatform.isAndroid)
              SizedBox(
                width: 150,
                height: 40,
                child: TextButton(
                  onPressed: ()async{
                    var brower = LoginInBrowser(() async{
                      CookieManager cookieManager = CookieManager.instance();
                      var id = await cookieManager.getCookie(url: Uri.parse(".e-hentai.org"), name: "ipb_member_id");
                      var hash = await cookieManager.getCookie(url: Uri.parse(".e-hentai.org"), name: "ipb_pass_hash");
                      try {
                        login(id!.value, hash!.value);
                      }
                      catch(e){
                        showMessage(Get.context, "登录失败");
                      }
                    });
                    await brower.openUrlRequest(urlRequest: URLRequest(url: Uri.parse("https://forums.e-hentai.org/index.php?act=Login&CODE=00")));
                  },
                  child: Row(
                    children: const [
                      Text("在Webview中登录"),
                      Icon(Icons.arrow_outward,size: 15,)
                    ],
                  ),
                ),
              ),
              if(GetPlatform.isAndroid)
              const SizedBox(height: 5,),
              SizedBox(
                width: 60,
                height: 40,
                child: TextButton(
                  onPressed: ()=>launchUrlString("https://forums.e-hentai.org/index.php?act=Reg&CODE=00",mode: LaunchMode.externalApplication),
                  child: Row(
                    children: const [
                      Text("注册"),
                      Icon(Icons.arrow_outward,size: 15,)
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 400,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.info_outline,size: 20,),
                    Text("由于需要captcha响应, 暂不支持直接密码登录",maxLines: 2,)
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void login(String id, String hash){
    setState(() {
      logging = true;
      appdata.ehId = id;
      appdata.ehPassHash = hash;
      EhNetwork().getUserName().then((b){
        if(b){
          Get.back();
          showMessage(context, "登录成功");
        }else{
          showMessage(context, EhNetwork().status?EhNetwork().message:"登录失败");
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