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
      title: Text("设置漫画排序模式".tr),
      children: [
        GetBuilder<SetJmComicsOrderController>(
          init: SetJmComicsOrderController(settingOrder),
          builder: (logic){
            return SizedBox(
              width: 400,
              child: Column(
                children: [
                  ListTile(
                    title: Text("最新".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "0",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("0"),
                  ),
                  ListTile(
                    title: settingOrder == 16?Text("总排行".tr):Text("最多点击".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "1",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("1"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("月排行".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "2",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("2"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("周排行".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "3",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("3"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("日排行".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "4",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("4"),
                  ),
                  ListTile(
                    title: Text("最多图片".tr),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "5",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("5"),
                  ),
                  ListTile(
                    title: Text("最多喜欢".tr),
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
            ListTile(
              title: Text("禁漫天堂".tr),
            ),
            ListTile(
              leading: Icon(Icons.sort, color: Theme.of(context).colorScheme.secondary),
              title: Text("分类中漫画排序模式".tr),
              trailing: Select(
                initialValue: int.parse(appdata.settings[16]),
                values: [
                  "最新".tr, "总排行".tr, "月排行".tr, "周排行".tr, "日排行".tr, "最多图片".tr, "最多喜欢".tr
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
              title: Text("搜索中漫画排序模式".tr),
              trailing: Select(
                initialValue: int.parse(appdata.settings[19]),
                values: [
                  "最新".tr, "最多点击".tr, "月排行".tr, "周排行".tr, "日排行".tr, "最多图片".tr, "最多喜欢".tr
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
              title: Text("设置分流".tr),
              trailing: Select(
                initialValue: int.parse(appdata.settings[17]),
                values: [
                  "分流1".tr,"分流2".tr,"分流3".tr,"分流4".tr
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
              title: Text("清除登录状态".tr),
              onTap: () => jmNetwork.logout(),
            ),
          ],
        ));
  }
}
