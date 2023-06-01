import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';

class JmLoginPage extends StatefulWidget {
  const JmLoginPage({Key? key}) : super(key: key);

  @override
  State<JmLoginPage> createState() => _JmLoginPageState();
}

class _JmLoginPageState extends State<JmLoginPage> {
  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  bool logging = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("登录禁漫天堂".tr),),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                TextField(
                  autofocus: false,
                  controller: nameController,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "账号".tr,
                      hintText: "账号".tr,
                      prefixIcon: const Icon(Icons.person)
                  ),
                ),
                const Padding(padding: EdgeInsets.all(5),),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "密码".tr,
                      hintText: "您的登录密码".tr,
                      prefixIcon: const Icon(Icons.lock)
                  ),
                  obscureText: true,
                  onSubmitted: (s)async{
                    setState(() {
                      logging = true;
                    });
                    var res = await jmNetwork.login(nameController.text, passwordController.text);
                    if(res.error){
                      showMessage(Get.context, res.errorMessage!);
                      setState(() {
                        logging = false;
                      });
                    }else{
                      Get.back();
                    }
                  },
                ),
                SizedBox.fromSize(size: const Size(5,10),),
                if(!logging)
                  SizedBox(
                    width: 90,
                    child: FilledButton(
                      child: Text("登录".tr),
                      onPressed: ()async{
                        setState(() {
                          logging = true;
                        });
                        var res = await jmNetwork.login(nameController.text, passwordController.text);
                        if(res.error){
                          showMessage(Get.context, res.errorMessage!);
                          try {
                            setState(() {
                              logging = false;
                            });
                          }
                          catch(e){
                            //忽视
                          }
                        }else{
                          Get.back();
                        }
                      },
                    ),
                  ),
                if(logging)
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                SizedBox(
                  width: 60,
                  height: 40,
                  child: TextButton(
                    onPressed: ()=>launchUrlString("https://18comic.vip/signup",mode: LaunchMode.externalApplication),
                    child: Row(
                      children: [
                        Text("注册".tr),
                        const Icon(Icons.arrow_outward,size: 15,)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
