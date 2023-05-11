import '../../base.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../widgets/select.dart';

///设置分类中漫画排序模式, 返回设置是否发生变化
Future<bool> setJmComicsOrder(BuildContext context, {bool search = false}) async{
  var settingOrder = search?19:16;

  var mode = appdata.settings[settingOrder];
  await showDialog(context: context, builder: (dialogContext){
    return SimpleDialog(
      title: const Text("设置漫画排序模式"),
      children: [
        GetBuilder<SetJmComicsOrderController>(
          init: SetJmComicsOrderController(settingOrder),
          builder: (logic){
            return SizedBox(
              width: 400,
              child: Column(
                children: [
                  ListTile(
                    title: const Text("最新"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "0",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("0"),
                  ),
                  ListTile(
                    title: settingOrder == 16?const Text("总排行"):const Text("最多点击"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "1",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("1"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: const Text("月排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "2",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("2"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: const Text("周排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "3",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("3"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: const Text("日排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "4",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("4"),
                  ),
                  ListTile(
                    title: const Text("最多图片"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "5",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("5"),
                  ),
                  ListTile(
                    title: const Text("最多喜欢"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "6",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("6"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  });
  return appdata.settings[settingOrder] == mode;
}

class SetJmComicsOrderController extends GetxController{
  int settingsOrder;
  SetJmComicsOrderController(this.settingsOrder);
  late String value = appdata.settings[settingsOrder];

  void set(String v){
    value = v;
    appdata.settings[settingsOrder] = v;
    appdata.writeData();
    Get.back();
  }
}


class JmSettings extends StatefulWidget {
  const JmSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<JmSettings> createState() => _JmSettingsState();
}

class _JmSettingsState extends State<JmSettings> {
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        child: Column(
          children: [
            const ListTile(
              title: Text("禁漫天堂"),
            ),
            ListTile(
              leading: Icon(Icons.sort, color: Theme.of(context).colorScheme.secondary),
              title: const Text("分类中漫画排序模式"),
              trailing: Select(
                initialValue: int.parse(appdata.settings[16]),
                values: const [
                  "最新", "总排行", "月排行", "周排行", "日排行", "最多图片", "最多喜欢"
                ],
                whenChange: (i){
                  appdata.settings[16] = i.toString();
                  appdata.updateSettings();
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.manage_search_outlined, color: Theme.of(context).colorScheme.secondary),
              title: const Text("搜索中漫画排序模式"),
              trailing: Select(
                initialValue: int.parse(appdata.settings[19]),
                values: const [
                  "最新", "最多点击", "月排行", "周排行", "日排行", "最多图片", "最多喜欢"
                ],
                whenChange: (i){
                  appdata.settings[19] = i.toString();
                  appdata.updateSettings();
                },
                disabledValues: const [2,3,4],
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.account_tree_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text("设置分流"),
              trailing: Select(
                initialValue: int.parse(appdata.settings[17]),
                values: const [
                  "分流1","分流2","分流3","分流4"
                ],
                whenChange: (i){
                  appdata.settings[17] = i.toString();
                  appdata.updateSettings();
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.secondary),
              title: const Text("清除登录状态"),
              onTap: () => jmNetwork.logout(),
            ),
          ],
        ));
  }
}
