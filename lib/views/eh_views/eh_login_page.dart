import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:get/get.dart';

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
                        setState(() {
                          logging = true;
                          appdata.ehId = c1.text;
                          appdata.ehPassHash = c2.text;
                          ehNetwork.getUserName().then((b){
                            if(b){
                              Get.back();
                              showMessage(context, "登录成功");
                            }else{
                              showMessage(context, ehNetwork.status?ehNetwork.message:"登录失败");
                              setState(() {
                                logging = false;
                              });
                            }
                          });
                        });
                      }
                    },
                  ):const CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 10,),
              SizedBox(
                width: 150,
                height: 30,
                child: TextButton(
                  onPressed: (){},
                  child: Row(
                    children: const [
                      Text("在Webview中登录"),
                      Icon(Icons.arrow_outward,size: 15,)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 5,),
              SizedBox(
                width: 60,
                height: 30,
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
                  children: const [
                    Icon(Icons.info_outline,size: 20,),
                    Text("由于E-Hentai登录需要captcha响应, 暂不支持使用密码登录")
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
