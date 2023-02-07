import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:url_launcher/url_launcher_string.dart';

class RadioLogic extends GetxController{
  int value = int.parse(appdata.appChannel)-1;
  void change(int i){
    value = i;
    appdata.appChannel = (i+1).toString();
    appdata.writeData();
    update();
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pageChangeValue = appdata.settings[0]=="1";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            centerTitle: true,
            title: const Text("设置"),
          ),
          SliverToBoxAdapter(
            child: Card(
              elevation: 0,
              child: Column(
                children: [
                  const ListTile(
                    title: Text("浏览"),
                  ),
                  ListTile(
                    leading: Icon(Icons.hub_outlined),
                    title: const Text("设置分流"),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: (){
                      Get.put(RadioLogic());
                      showDialog(context: context, builder: (BuildContext context) => Dialog(
                        child: GetBuilder<RadioLogic>(builder: (radioLogic){
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ListTile(title: Text("选择分流"),),
                              ListTile(
                                trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                  radioLogic.change(i!);
                                },),
                                title: const Text("分流1"),
                                onTap: (){
                                  radioLogic.change(0);
                                },
                              ),
                              ListTile(
                                trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                                  radioLogic.change(i!);
                                },),
                                title: const Text("分流2"),
                                onTap: (){
                                  radioLogic.change(1);
                                },
                              ),
                              ListTile(
                                trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                                  radioLogic.change(i!);
                                  appdata.appChannel = (i+1).toString();
                                },),
                                title: const Text("分流3"),
                                onTap: (){
                                  radioLogic.change(2);
                                },
                              ),
                            ],
                          );
                        },),
                      ));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.switch_left),
                    title: const Text("点击屏幕左右翻页"),
                    trailing: Switch(
                      value: pageChangeValue,
                      onChanged: (b){
                        b?appdata.settings[0] = "1":appdata.settings[0]="0";
                        setState(() {
                          pageChangeValue = b;
                        });
                        appdata.writeData();
                      },
                    ),
                    onTap: (){},
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverToBoxAdapter(
              child: Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("关于"),
                    ),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text("PicaComic"),
                      subtitle: SelectableText("本软件仅用于学习交流"),
                    ),
                    ListTile(
                      leading: const Icon(Icons.update),
                      title: const Text("查看最新版本"),
                      subtitle: const SelectableText("当前: v1.1.2"),
                      onTap: (){
                        launchUrlString("https://github.com/wgh136/PicaComic/releases",mode: LaunchMode.externalApplication);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_outward),
                      title: const Text("项目地址"),
                      subtitle: const SelectableText("https://github.com/wgh136/PicaComic"),
                      onTap: (){
                        launchUrlString("https://github.com/wgh136/PicaComic",mode: LaunchMode.externalApplication);
                      },
                    ),
                  ],
                ),
              )
          )
        ],
      ),
    );
  }
}
