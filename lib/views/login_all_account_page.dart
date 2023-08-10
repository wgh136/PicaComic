import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/settings/ht_settings.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class LoginAccountsPage extends StatefulWidget {
  const LoginAccountsPage({Key? key}) : super(key: key);

  @override
  State<LoginAccountsPage> createState() => _LoginAccountsPageState();
}

class _LoginAccountsPageState extends State<LoginAccountsPage> {
  bool isLoading = true;
  String? message;
  String status = "正在获取用户信息".tl;

  @override
  void initState() {
    login();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(isLoading)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: 200,child: LinearProgressIndicator(),),
                    ),
                  if(!isLoading)
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(Icons.error_outline,size:60,),
                    ),
                  const SizedBox(height: 8,),
                  if(isLoading)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(status),
                    ),
                  if(isLoading)
                    SizedBox(
                      width: 80,
                      height: 40,
                      child: Center(
                        child: TextButton(
                          child: Text("跳过".tl),
                          onPressed: ()=>Get.offAll(() => const MainPage()),
                        ),
                      ),
                    ),
                  if(!isLoading)
                    Align(
                      alignment: Alignment.topCenter,
                      child: Text(message??"网络错误".tl, textAlign: TextAlign.center,),
                    ),
                  if(!isLoading)
                    Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 180,
                          height: 50,
                          child: Row(
                            children: [
                              FilledButton.tonal(
                                onPressed: (){
                                  setState(() {
                                    isLoading = true;
                                    login();
                                  });
                                },
                                child: Text("重试".tl),
                              ),
                              const Spacer(),
                              FilledButton.tonal(
                                onPressed: () => goToMainPage(),
                                child: Text("跳过".tl),
                              )
                            ],
                          ),
                        )
                    ),
                ],
              )
          )),
          if(!isLoading)
            SizedBox(
              width: 400,
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text("设置".tl),
                trailing: const Icon(Icons.arrow_right),
                onTap: ()=>Get.to(()=>const SettingsPage()),
              ),
            ),
          SizedBox(height: MediaQuery.of(context).padding.bottom,)
        ],
      )
    );
  }

  void goToMainPage(){
    if(appdata.settings[13]=="1"){
      Get.offAll(()=>const AuthPage());
    }else{
      Get.offAll(()=>const MainPage());
    }
  }

  ///获取哔咔账号信息, 登录禁漫账号
  Future<void> login() async{
    message = null;
    if(!HtSettings.htUrls.contains(appdata.settings[31])){
      appdata.settings[31] = HtSettings.htUrls[0];
      appdata.updateSettings();
    }
    if(appdata.token != "") {
      try {
        var res = await network.getProfile();
        if (res.error) {
          message = res.errorMessage;
        } else {
          appdata.user = res.data;
          await appdata.writeData();
        }
      }
      catch(e){
        message = "登录哔咔时发生错误\n".tl + e.toString();
      }
    }
    try {
      setState(() {
        status = "正在登录禁漫";
      });
    }
    catch(e){
      //忽视
    }
    var res2 = await jmNetwork.loginFromAppdata();
    if(res2.error){
      message = res2.errorMessage;
      message = "登录禁漫时发生错误\n".tl + message.toString();
    }
    try {
      setState(() {
        status = "正在登录绅士漫画";
      });
    }
    catch(e){
      //忽视
    }
    var res3 = await HtmangaNetwork().loginFromAppdata();
    if(res3.error){
      message = res3.errorMessage;
      message = "登录绅士漫画时发生错误\n".tl + message.toString();
    }
    if(message == null){
      goToMainPage();
    }else{
      try {
        setState(() {
          isLoading = false;
        });
      }
      catch(e){
        //已退出页面
      }
    }
  }
}