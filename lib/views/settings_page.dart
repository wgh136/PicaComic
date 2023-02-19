import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/update.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/theme_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'me_page.dart';

void setSearchMode(BuildContext context){
  showDialog(context: context, builder: (context){
    return SimpleDialog(
      title: const Text("选择漫画排序模式"),
      children: [GetBuilder<ModeRadioLogic2>(
        init: ModeRadioLogic2(),
        builder: (radioLogic){
          return Column(
            children: [
              const SizedBox(width: 400,),
              ListTile(
                trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.change(i!);
                },),
                title: const Text("新书在前"),
                onTap: (){
                  radioLogic.change(0);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.change(i!);
                },),
                title: const Text("旧书在前"),
                onTap: (){
                  radioLogic.change(1);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.change(i!);
                  appdata.appChannel = (i+1).toString();
                },),
                title: const Text("最多喜欢"),
                onTap: (){
                  radioLogic.change(2);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.change(i!);
                  appdata.appChannel = (i+1).toString();
                },),
                title: const Text("最多指名"),
                onTap: (){
                  radioLogic.change(3);
                },
              ),
            ],
          );
        },),]
    );
  });
}

void setShut(BuildContext context){
  showDialog(context: context, builder: (BuildContext context) => SimpleDialog(
    title: const Text("选择分流"),
    children: [GetBuilder<RadioLogic>(
      init: RadioLogic(),
      builder: (radioLogic){
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 400,),
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
              },),
              title: const Text("分流3"),
              onTap: (){
                radioLogic.change(2);
              },
            ),
          ],
        );
      },),]
  ));
}

void findUpdate(BuildContext context){
  showMessage(context, "正在检查更新");
  checkUpdate().then((b){
    if(b==null){
      showMessage(context, "网络错误");
    } else if(b){
      getUpdatesInfo().then((s){
        if(s!=null){
          showDialog(context: context, builder: (context){
            return AlertDialog(
              title: const Text("有可用更新"),
              content: Text(s),
              actions: [
                TextButton(onPressed: (){Get.back();appdata.settings[2]="0";appdata.writeData();}, child: const Text("关闭更新检查")),
                TextButton(onPressed: (){Get.back();}, child: const Text("取消")),
                TextButton(
                    onPressed: (){
                      getDownloadUrl().then((s){
                        launchUrlString(s,mode: LaunchMode.externalApplication);
                      });
                    },
                    child: const Text("下载"))
              ],
            );
          });
        }else{
          showMessage(context, "网络错误");
        }
      });
    }else{
      showMessage(context, "已是最新版本");
    }
  });
}

void giveComments(BuildContext context){
  showDialog(context: context, builder: (context){
    return SimpleDialog(
      title: const Text("提出建议"),
      children: [
        ListTile(
          leading: const Image(image: AssetImage("images/github.png"),width: 25,),
          title: const Text("在Github上提出Issue"),
          onTap: (){launchUrlString("https://github.com/wgh136/PicaComic/issues",mode: LaunchMode.externalApplication);},
        ),
        ListTile(
          leading: const Icon(Icons.mail),
          title: const Text("发送邮件"),
          onTap: (){launchUrlString("mailto:wgh1624044369@gmail.com",mode: LaunchMode.externalApplication);},
        ),
      ],
    );
  });
}

class RadioLogic extends GetxController{
  int value = int.parse(appdata.appChannel)-1;
  void change(int i){
    value = i;
    appdata.appChannel = (i+1).toString();
    appdata.writeData();
    update();
  }
}

class ModeRadioLogic2 extends GetxController{
  int value = appdata.getSearchMod();
  void change(int i){
    value = i;
    appdata.saveSearchMode(i);
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
  bool checkUpdateValue = appdata.settings[2]=="1";
  bool useMyServer = appdata.settings[3]=="1";
  bool showThreeButton = appdata.settings[4]=="1";
  bool showFrame = appdata.settings[5]=="1";
  bool punchIn = appdata.settings[6]=="1";

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
                    leading:Icon(Icons.hub_outlined,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("设置分流"),
                    trailing: const Icon(Icons.arrow_right,),
                    onTap: (){
                      setShut(context);
                    },
                  ),

                  if(!GetPlatform.isWeb)
                  ListTile(
                    leading: Icon(Icons.change_circle,color: Theme.of(context).colorScheme.secondary),
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
                  ListTile(
                    leading: Icon(Icons.manage_search_outlined,color: Theme.of(context).colorScheme.secondary),
                    trailing: const Icon(Icons.arrow_right),
                    title: const Text("设置搜索及分类排序模式"),
                    onTap: (){
                      setSearchMode(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.circle_outlined,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("显示头像框"),
                    trailing: Switch(
                      value: showFrame,
                      onChanged: (b){
                        b?appdata.settings[5] = "1":appdata.settings[5]="0";
                        setState(() {
                          showFrame = b;
                        });
                        var t = Get.find<InfoController>();
                        t.update();
                        appdata.writeData();
                      },
                    ),
                    onTap: (){},
                  ),
                  ListTile(
                    leading: Icon(Icons.today,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("启动时打卡"),
                    onTap: (){},
                    trailing: Switch(
                      value: punchIn,
                      onChanged: (b){
                        b?appdata.settings[6] = "1":appdata.settings[6]="0";
                        setState(() {
                          punchIn = b;
                        });
                        appdata.writeData();
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.color_lens,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("设置主题"),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: (){
                      Get.to(()=>const ThemePage());
                    },
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
                    title: Text("阅读"),
                  ),
                  ListTile(
                    leading: Icon(Icons.switch_left,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("点击屏幕左右区域翻页"),
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
                  ListTile(
                    leading: Icon(Icons.control_camera,color: Theme.of(context).colorScheme.secondary),
                    title: const Text("宽屏时显示前进后退关闭按钮"),
                    subtitle: const Text("优化鼠标阅读体验"),
                    onTap: (){},
                    trailing: Switch(
                      value: showThreeButton,
                      onChanged: (b){
                        b?appdata.settings[4] = "1":appdata.settings[4]="0";
                        setState(() {
                          showThreeButton = b;
                        });
                        appdata.writeData();
                      },
                    ),
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
                    ListTile(
                      leading: Icon(Icons.info_outline,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("PicaComic"),
                      subtitle: const Text("本软件仅用于学习交流"),
                      onTap: (){
                        showMessage(context, "禁止涩涩");
                      },
                    ),
                    if(!GetPlatform.isWeb)
                    ListTile(
                      leading: Icon(Icons.update,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("检查更新"),
                      subtitle: const Text("当前: $appVersion"),
                      onTap: (){
                        findUpdate(context);
                      },
                    ),
                    if(!GetPlatform.isWeb)
                    ListTile(
                      leading: Icon(Icons.security_update,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("启动时检查更新"),
                      trailing: Switch(
                        value: checkUpdateValue,
                        onChanged: (b){
                          b?appdata.settings[2] = "1":appdata.settings[2]="0";
                          setState(() {
                            checkUpdateValue = b;
                          });
                          appdata.writeData();
                        },
                      ),
                      onTap: (){},
                    ),
                    ListTile(
                      leading: Icon(Icons.code,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("项目地址"),
                      subtitle: const Text("https://github.com/wgh136/PicaComic"),
                      onTap: (){
                        launchUrlString("https://github.com/wgh136/PicaComic",mode: LaunchMode.externalApplication);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.chat,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("提出建议"),
                      onTap: (){giveComments(context);},
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
