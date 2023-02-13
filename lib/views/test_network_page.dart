import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'base.dart';

class TestNetworkPage extends StatefulWidget {
  const TestNetworkPage({Key? key}) : super(key: key);

  @override
  State<TestNetworkPage> createState() => _TestNetworkPageState();
}

class _TestNetworkPageState extends State<TestNetworkPage> {
  bool isLoading = true;
  bool flag = true;
  bool useMyServer = appdata.settings[3]=="1";
  @override
  Widget build(BuildContext context) {
    if(flag) {
      flag = false;
      network.getProfile().then((p){
      if(p!=null){
        appdata.user = p;
        Get.offAll(()=>const MainPage());
      }else {
        setState(() {
        isLoading = false;
      });
      }
    });
    }
    return Scaffold(
      body: Stack(
        children: [
          if(isLoading)
            Positioned(
              top: MediaQuery.of(context).size.height/2-50,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: CircularProgressIndicator(),
              ),
            ),
          if(!isLoading)
            Positioned(
              top: MediaQuery.of(context).size.height/2-100,
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
              top: MediaQuery.of(context).size.height/2+10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("正在获取用户信息"),
              ),
            ),
          if(!isLoading)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-30,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),


          if(!isLoading)
            Positioned(
              top: MediaQuery.of(context).size.height/2+10,
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
                              Get.offAll(()=>const MainPage());
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
                          showDialog(context: context, builder: (context){
                            return AlertDialog(
                              content: const Text("这将删除当前登录信息是否继续?"),
                              actions: [
                                TextButton(onPressed: (){Get.back();}, child: const Text("取消")),
                                TextButton(onPressed: (){
                                  appdata.clear();
                                  Get.offAll(const LoginPage());
                                }, child: const Text("确认"))
                              ],
                            );
                          });
                        },
                        child: const Text("退出登录"),
                      )
                    ],
                  ),
                )
              ),
            ),
          if(!isLoading)
            Positioned(
              left: MediaQuery.of(context).size.width/2-150,
              right: MediaQuery.of(context).size.width/2-150,
              top: MediaQuery.of(context).size.height/2+110,
              child: SizedBox(
                width: 300,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox.fromSize(size: const Size(5, 1),),
                            const Text("注意",style: TextStyle(fontWeight: FontWeight.w600),)
                          ],
                        ),
                        const Text("此情况可能是登录失效导致, 暂时不知道登录失效会返回什么, 如果网络没有问题请点击重新登录")
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if(!isLoading&&!GetPlatform.isWeb)
            Positioned(
              bottom: 20,
              left: MediaQuery.of(context).size.width/2-200,
              child: SizedBox(
                width: 400,
                child: ListTile(
                  leading: const Icon(Icons.change_circle),
                  title: const Text("使用转发服务器"),
                  subtitle: const Text("自己有魔法会减慢速度"),
                  trailing: Switch(
                    value: useMyServer,
                    onChanged: (b){
                      b?appdata.settings[3] = "1":appdata.settings[3]="0";
                      setState(() {
                        useMyServer = b;
                      });
                      network.updateApi();
                      appdata.writeData();
                    },
                  ),
                  onTap: (){},
                ),
              ),
            )
        ],
      )
    );
  }
}
