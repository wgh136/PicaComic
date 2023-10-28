import 'package:pica_comic/foundation/app.dart';
import '../../base.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../widgets/select.dart';
import 'package:pica_comic/tools/translations.dart';

///设置分类中漫画排序模式, 返回设置是否发生变化
Future<bool> setJmComicsOrder(BuildContext context, {bool search = false}) async{
  var settingOrder = search?19:16;

  var mode = appdata.settings[settingOrder];
  await showDialog(context: context, builder: (dialogContext){
    return SimpleDialog(
      title: Text("设置漫画排序模式".tl),
      children: [
        StateBuilder<SetJmComicsOrderController>(
          init: SetJmComicsOrderController(settingOrder),
          builder: (logic){
            return SizedBox(
              width: 400,
              child: Column(
                children: [
                  ListTile(
                    title: Text("最新".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "0",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("0"),
                  ),
                  ListTile(
                    title: settingOrder == 16?Text("总排行".tl):Text("最多点击".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "1",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("1"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("月排行".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "2",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("2"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("周排行".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "3",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("3"),
                  ),
                  if(settingOrder == 16)
                  ListTile(
                    title: Text("日排行".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "4",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("4"),
                  ),
                  ListTile(
                    title: Text("最多图片".tl),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "5",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("5"),
                  ),
                  ListTile(
                    title: Text("最多喜欢".tl),
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

class SetJmComicsOrderController extends StateController{
  int settingsOrder;
  SetJmComicsOrderController(this.settingsOrder);
  late String value = appdata.settings[settingsOrder];

  void set(String v){
    value = v;
    appdata.settings[settingsOrder] = v;
    appdata.writeData();
    App.globalBack();
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
              title: Text("禁漫天堂".tl),
            ),
            ListTile(
              leading: Icon(Icons.sort, color: Theme.of(context).colorScheme.secondary),
              title: Text("分类中漫画排序模式".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[16]),
                values: [
                  "最新".tl, "总排行".tl, "月排行".tl, "周排行".tl, "日排行".tl, "最多图片".tl, "最多喜欢".tl
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
              title: Text("搜索中漫画排序模式".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[19]),
                values: [
                  "最新".tl, "最多点击".tl, "月排行".tl, "周排行".tl, "日排行".tl, "最多图片".tl, "最多喜欢".tl
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
              leading: Icon(Icons.favorite_border, color: Theme.of(context).colorScheme.secondary),
              title: Text("收藏夹中漫画排序模式".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[42]),
                values: [
                  "最新收藏".tl, "最新更新".tl
                ],
                whenChange: (i){
                  appdata.settings[42] = i.toString();
                  appdata.updateSettings();
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.account_tree_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("API分流".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[17]),
                values: [
                  "分流1".tl,"分流2".tl,"分流3".tl,"分流4".tl, "转发服务器".tl
                ],
                whenChange: (i){
                  appdata.settings[17] = i.toString();
                  appdata.updateSettings();
                  JmNetwork().loginFromAppdata();
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.image,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("图片分流".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[37]),
                values: [
                  "分流1".tl,"分流2".tl,"分流3".tl,"分流4".tl, "分流5".tl, "分流6".tl
                ],
                whenChange: (i){
                  appdata.settings[37] = i.toString();
                  appdata.updateSettings();
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.secondary),
              title: Text("清除登录状态".tl),
              onTap: () => jmNetwork.logout(),
            ),
          ],
        ));
  }
}
