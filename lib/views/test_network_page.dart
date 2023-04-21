import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';

class TestNetworkPage extends StatefulWidget {
  const TestNetworkPage({Key? key}) : super(key: key);

  @override
  State<TestNetworkPage> createState() => _TestNetworkPageState();
}

class _TestNetworkPageState extends State<TestNetworkPage> {
  bool isLoading = true;
  bool flag = true;
  @override
  Widget build(BuildContext context) {
    if(flag) {
      flag = false;
      network.updateApi().then((v){
        network.getProfile().then((p){
          if(p!=null){
            appdata.user = p;
            goToMainPage();
          }else {
            setState(() {
              isLoading = false;
            });
          }
        });
      });
    }
    return Scaffold(
      appBar: AppBar(),
      body: Material(
        child: Stack(
          children: [
            if(isLoading)
              Positioned(
                top: MediaQuery.of(context).size.height/2-100,
                left: 0,
                right: 0,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: CircularProgressIndicator(),
                ),
              ),
            if(!isLoading)
              Positioned(
                top: MediaQuery.of(context).size.height/2-150,
                left: 0,
                right: 0,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.error_outline,size:60,),
                ),
              ),
            if(isLoading)
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height/2-40,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Text("正在获取用户信息"),
                ),
              ),
            if(!isLoading)
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height/2-80,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: network.status?Text(network.message):const Text("网络错误"),
                ),
              ),

            if(!isLoading)
              Positioned(
                top: MediaQuery.of(context).size.height/2-40,
                left: 0,
                right: 0,
                child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 200,
                      height: 50,
                      child: Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: (){
                              setState(() {
                                isLoading = true;
                              });
                              network.getProfile().then((p){
                                if(p!=null){
                                  appdata.user = p;
                                  goToMainPage();
                                }else {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              });
                            },
                            child: const Text("   重试   "),
                          ),
                          const Spacer(),
                          FilledButton.tonal(
                            onPressed: (){
                              if(GetPlatform.isWeb){
                                showMessage(context, "Web端不支持下载");
                                return;
                              }
                              Get.to(()=>const DownloadPage(noNetwork: true,));
                            },
                            child: const Text("已下载"),
                          )
                        ],
                      ),
                    )
                ),
              ),
            if(!isLoading&&!GetPlatform.isWeb)
              Positioned(
                bottom: 20,
                left: MediaQuery.of(context).size.width/2-200,
                child: SizedBox(
                  width: 400,
                  child: ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("转到设置"),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: ()=>Get.to(()=>const SettingsPage()),
                  ),
                ),
              )
          ],
        ),
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
}
