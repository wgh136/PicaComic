import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/update.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/proxy.dart';
import 'package:pica_comic/views/blocking_keyword_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
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
                },),
                title: const Text("最多喜欢"),
                onTap: (){
                  radioLogic.change(2);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.change(i!);
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
  showMessage(context, "正在检查更新",time: 2);
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
                TextButton(onPressed: ()=>Get.back(), child: const Text("取消")),
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
          leading: Icon(Icons.mail,color: Theme.of(context).colorScheme.secondary),
          title: const Text("发送邮件"),
          onTap: (){launchUrlString("mailto:wgh1624044369@gmail.com",mode: LaunchMode.externalApplication);},
        ),
      ],
    );
  });
}

void setReadingMethod(BuildContext context){
  showDialog(context: context, builder: (BuildContext context) => SimpleDialog(
      title: const Text("选择阅读模式"),
      children: [GetBuilder<ReadingMethodLogic>(
        init: ReadingMethodLogic(),
        builder: (radioLogic){
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 400,),
              ListTile(
                trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从左至右"),
                onTap: (){
                  radioLogic.setValue(1);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从右至左"),
                onTap: (){
                  radioLogic.setValue(2);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从上至下"),
                onTap: (){
                  radioLogic.setValue(3);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 4,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从上至下(连续)"),
                onTap: (){
                  radioLogic.setValue(4);
                },
              ),
            ],
          );
        },),]
  ));
}

class ReadingMethodLogic extends GetxController{
  var value = int.parse(appdata.settings[9]);

  void setValue(int i){
    value = i;
    appdata.settings[9] = value.toString();
    update();
  }
}

void setImageQuality(BuildContext context){
  showDialog(context: context, builder: (BuildContext context) => SimpleDialog(
      title: const Text("设置图片质量"),
      children: [GetBuilder<SetImageQualityLogic>(
        init: SetImageQualityLogic(),
        builder: (radioLogic){
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 400,),
              ListTile(
                trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("低"),
                onTap: (){
                  radioLogic.setValue(1);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("中"),
                onTap: (){
                  radioLogic.setValue(2);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("高"),
                onTap: (){
                  radioLogic.setValue(3);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 4,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("原图"),
                onTap: (){
                  radioLogic.setValue(4);
                },
              ),
            ],
          );
        },),]
  ));
}

class SetImageQualityLogic extends GetxController{
  var value = appdata.getQuality();

  void setValue(int i){
    value = i;
    appdata.setQuality(i);
    update();
  }
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

class CalculateCacheLogic extends GetxController{
  bool calculating = true;
  double size = 0;
  void change(){
    calculating = !calculating;
    update();
  }
  void get()async{
    size = await calculateCacheSize();
    change();
  }
}

class ProxyController extends GetxController{
  bool value = appdata.settings[8] == "0";
  late var controller = TextEditingController(
    text: value?"":appdata.settings[8]
  );
}

void setProxy(BuildContext context){
  showDialog(context: context, builder: (dialogContext){
    return GetBuilder(
      init: ProxyController(),
      builder: (controller){
        return SimpleDialog(
          title: const Text("设置代理"),
          children: [
            const SizedBox(width: 400,),
            ListTile(
              title: const Text("使用系统代理"),
              subtitle: const Text("仅Windows端有效"),
              trailing: Switch(
                value: controller.value,
                onChanged: (value){
                  if(value == true){
                    controller.controller.text = "";
                  }
                  controller.value = !controller.value;
                  controller.update();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
              child: TextField(
                readOnly: controller.value,
                controller: controller.controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: controller.value?"使用系统代理时无法手动设置":"设置代理, 例如127.0.0.1:8080"
                ),
              ),
            ),
            Center(
              child: FilledButton(onPressed: (){
                if(controller.value){
                  appdata.settings[8] = "0";
                  appdata.writeData();
                  setImageProxy();
                  Get.back();
                }else{
                  appdata.settings[8] = controller.controller.text;
                  appdata.writeData();
                  setImageProxy();
                  Get.back();
                }
              }, child: const Text("确认")),
            )
          ],
        );
      }
    );
  });
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({this.popUp=false,Key? key}) : super(key: key);
  final bool popUp;

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
  bool useVolumeKeyChangePage = appdata.settings[7]=="1";
  bool blockScreenshot = appdata.settings[12]=="1";
  bool needBiometrics = appdata.settings[13]=="1";

  @override
  Widget build(BuildContext context) {
    var body = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("浏览"),
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
                      leading: Icon(Icons.block,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("关键词屏蔽"),
                      onTap: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context)=>BlockingKeywordPage(popUp: widget.popUp,))),
                      trailing: const Icon(Icons.arrow_right),
                    ),
                    ListTile(
                      leading: Icon(Icons.image,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("设置图片质量"),
                      onTap: ()=>setImageQuality(context),
                      trailing: const Icon(Icons.arrow_right),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("网络"),
                    ),
                    if(!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.change_circle,color: Theme.of(context).colorScheme.secondary),
                        title: const Text("使用转发服务器"),
                        subtitle: const Text("同时使用网络代理工具会减慢速度"),
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
                      leading:Icon(Icons.hub_outlined,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("设置分流"),
                      trailing: const Icon(Icons.arrow_right,),
                      onTap: (){
                        setShut(context);
                      },
                    ),
                    if(!GetPlatform.isWeb)
                      ListTile(
                        leading:Icon(Icons.network_ping,color: Theme.of(context).colorScheme.secondary),
                        title: const Text("设置代理"),
                        trailing: const Icon(Icons.arrow_right,),
                        onTap: (){
                          setProxy(context);
                        },
                      ),
                  ],
                ),
              ),
              const Divider(),
              Card(
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
                          setState(()=>pageChangeValue = b);
                          appdata.writeData();
                        },
                      ),
                      onTap: (){},
                    ),
                    ListTile(
                      leading: Icon(Icons.volume_mute,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("使用音量键翻页"),
                      subtitle: const Text("仅安卓端有效"),
                      trailing: Switch(
                        value: useVolumeKeyChangePage,
                        onChanged: (b){
                          b?appdata.settings[7] = "1":appdata.settings[7]="0";
                          setState(()=>useVolumeKeyChangePage = b);
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
                    ListTile(
                      leading: Icon(Icons.chrome_reader_mode,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("选择阅读模式"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: ()=>setReadingMethod(context),
                    )
                  ],
                ),
              ),
              const Divider(),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("App"),
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
                            setState(()=>checkUpdateValue = b);
                            appdata.writeData();
                          },
                        ),
                        onTap: (){},
                      ),
                    if(!GetPlatform.isWeb)
                    GetBuilder<CalculateCacheLogic>(
                        init: CalculateCacheLogic(),
                        builder: (logic){
                          if(logic.calculating){
                            logic.get();
                            return ListTile(
                              leading: Icon(Icons.storage,color: Theme.of(context).colorScheme.secondary),
                              title: const Text("缓存大小"),
                              subtitle: const Text("计算中"),
                              onTap: (){},
                            );
                          }else{
                            return ListTile(
                              leading: Icon(Icons.storage,color: Theme.of(context).colorScheme.secondary),
                              title: const Text("清除缓存"),
                              subtitle: Text("${logic.size==double.infinity?"未知":logic.size.toStringAsFixed(2)} MB"),
                              onTap: (){
                                if(GetPlatform.isAndroid){
                                  eraseCache();
                                  logic.size = 0;
                                  logic.update();
                                }
                              },
                            );
                          }
                        }
                    )
                  ],
                ),
              ),
              if(!GetPlatform.isWeb)
              const Divider(),
              if(!GetPlatform.isWeb)
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("隐私"),
                    ),
                    if(GetPlatform.isAndroid)
                    ListTile(
                      leading: Icon(Icons.screenshot,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("阻止屏幕截图"),
                      subtitle: const Text("需要重启App以应用更改"),
                      trailing: Switch(
                        value: blockScreenshot,
                        onChanged: (b){
                          b?appdata.settings[12] = "1":appdata.settings[12]="0";
                          setState(()=>blockScreenshot = b);
                          appdata.writeData();
                        },
                      ),
                      onTap: ()=>showMessage(context, "禁止涩涩"),
                    ),
                    ListTile(
                      leading: Icon(Icons.security,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("启动时需要生物识别"),
                      subtitle: const Text("如果系统中未设置任何认证方法请勿开启"),
                      trailing: Switch(
                        value: needBiometrics,
                        onChanged: (b){
                          b?appdata.settings[13] = "1":appdata.settings[13]="0";
                          setState(()=>needBiometrics = b);
                          appdata.writeData();
                        },
                      ),
                      onTap: ()=>showMessage(context, "禁止涩涩"),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Card(
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
                      onTap: ()=>showMessage(context, "禁止涩涩"),
                    ),
                    ListTile(
                      leading: Icon(Icons.code,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("项目地址"),
                      subtitle: const Text("https://github.com/wgh136/PicaComic"),
                      onTap: ()=>launchUrlString("https://github.com/wgh136/PicaComic",mode: LaunchMode.externalApplication),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat,color: Theme.of(context).colorScheme.secondary),
                      title: const Text("提出建议"),
                      onTap: ()=>giveComments(context),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
      ],
    );
    if(widget.popUp){
      return PopUpWidgetScaffold(
          title: "设置",
          body: body
      );
    }else {
      return Scaffold(
        appBar: AppBar(title: const Text("设置")),
        body: body,
      );
    }
  }
}
