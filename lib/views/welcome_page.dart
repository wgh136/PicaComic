import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/accounts_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/settings/reading_settings.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/select.dart';

import '../base.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    network.updateApi();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity,0),
        child: AppBar(),
      ),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 300,
          child: Column(
            children: [
              const SizedBox(
                width: 100,
                height: 100,
                child: CircleAvatar(backgroundImage: AssetImage("images/app_icon.png"),),
              ),
              const Padding(padding: EdgeInsets.only(top: 20),child: Text(" Pica Comic",style: TextStyle(fontSize: 20),),),
              SizedBox(
                width: 200,
                height: 40,
                child: Center(
                  child: TextButton(
                    child: Text("开始使用".tr),
                    onPressed: () => Get.off(()=>const GuidePage()),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class GuidePage extends StatefulWidget {
  const GuidePage({super.key});

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> {
  var controller = PageController();
  bool showFinish = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
      floatingActionButton: !showFinish?FloatingActionButton.extended(
        onPressed: (){
          controller.animateToPage((controller.page!+1).toInt(), duration: const Duration(milliseconds: 300), curve: Curves.ease);
        },
        label: Text("继续".tr),
        icon: const Icon(Icons.navigate_next),
      ):FloatingActionButton.extended(
        onPressed: () => Get.offAll(const MainPage()),
        label: Text("完成".tr),
        icon: const Icon(Icons.check),
      ),
      body: SafeArea(
        child: PageView(
          controller: controller,
          onPageChanged: (i){
            if(i == 7){
              setState(() {
                showFinish = true;
              });
            }
          },
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("使用前须知", style: TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Text(
                    "感谢使用本软件, 请注意:\n\n".tr + "本App的开发目的仅为学习交流与个人兴趣, 无任何获利\n\n".tr + "此项目与Picacg, e-hentai.org, JmComic, hitomi.la无任何关系".tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("开始设置", style: TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Text(
                    "下面将进行一些基本设置, 所有的设置在之后均可进行更改".tr,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("漫画列表显示方式".tr, style: const TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 300,
                        width: 400,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8,),
                            Text("选择应当如何显示漫画".tr, style: const TextStyle(fontSize: 20),),
                            const SizedBox(height: 8,),
                            RadioListTile<String>(title: Text("顺序显示".tr),value: "0", groupValue: appdata.settings[25], onChanged: (s){
                              setState(() {
                                appdata.settings[25] = s!;
                              });
                              appdata.updateSettings();
                            }),
                            RadioListTile<String>(title: Text("分页显示".tr),value: "1", groupValue: appdata.settings[25], onChanged: (s){
                              setState(() {
                                appdata.settings[25] = s!;
                              });
                              appdata.updateSettings();
                            }),
                            const SizedBox(height: 8,),
                            Text("探索页面不受此设置影响\n顺序显示时, 当下滑至顶部将自动加载下一页, 并且添加至页面底部;\n"
                                "分页显示时, 将会在页面底部显示当前页面的序号和切换页面的按钮, 可以手动输入页数".tr)
                          ],
                        ),
                      ),
                    ),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("阅读设置".tr, style: const TextStyle(fontSize: 28),),
                ),
                const Expanded(child: Center(child: Padding(
                  padding: EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Card(
                    elevation: 5,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: 400,
                        child: ReadingSettings(false),
                      ),
                    ),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("App外观".tr, style: const TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Card(
                    elevation: 5,
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                            child: Text("设置App外观".tr, style: const TextStyle(fontSize: 18),),
                          ),
                          ListTile(
                            leading: Icon(Icons.color_lens,
                                color: Theme.of(context).colorScheme.secondary),
                            title: Text("主题选择".tr),
                            trailing: Select(
                              initialValue: int.parse(appdata.settings[27]),
                              values: const ["动态", "Blue", "Light Blue", "Indigo", "Purple", "Pink", "Cyan", "Teal", "Yellow", "Brown"],
                              whenChange: (i){
                                appdata.settings[27] = i.toString();
                                appdata.updateSettings();
                                Get.forceAppUpdate();
                              },
                              inPopUpWidget: false,
                              width: 140,
                            ),
                          ),
                          ListTile(
                            leading: Icon(Icons.dark_mode,
                                color: Theme.of(context).colorScheme.secondary),
                            title: Text("深色模式".tr),
                            trailing: Select(
                              initialValue: int.parse(appdata.settings[32]),
                              values: ["跟随系统".tr, "禁用".tr, "启用".tr],
                              whenChange: (i){
                                appdata.settings[32] = i.toString();
                                appdata.updateSettings();
                                Get.forceAppUpdate();
                              },
                              inPopUpWidget: false,
                              width: 140,
                            ),
                          ),
                          const SizedBox(height: 8,)
                        ],
                      ),
                    ),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("更多".tr, style: const TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Card(
                    elevation: 5,
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                            child: Text("在设置中更改更多选项".tr, style: const TextStyle(fontSize: 18),),
                          ),
                          ListTile(
                            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary,),
                            title: const Text("设置"),
                            trailing: const Icon(Icons.arrow_right),
                            onTap: ()=>showAdaptiveWidget(context, SettingsPage(popUp: MediaQuery.of(context).size.width>600,)),
                          ),
                          const SizedBox(height: 8,)
                        ],
                      ),
                    ),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("登录".tr, style: const TextStyle(fontSize: 28),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Card(
                    elevation: 5,
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                            child: Text("在账号管理页面登录账号".tr, style: const TextStyle(fontSize: 18),),
                          ),
                          ListTile(
                            leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary,),
                            title: Text("打开账号管理页面".tr),
                            trailing: const Icon(Icons.arrow_right),
                            onTap: ()=>showAdaptiveWidget(context, AccountsPage()),
                          ),
                          const SizedBox(height: 8,),
                        ],
                      ),
                    ),
                  ),
                ),))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 0, 0),
                  child: Text("完成".tr, style: const TextStyle(fontSize: 30),),
                ),
                Expanded(child: Center(child: Padding(
                  padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
                  child: Text("祝使用愉快".tr, style: const TextStyle(fontSize: 18),),
                ),))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
