import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../base.dart';
import '../me_page.dart';
import '../widgets/select.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class PicacgSettings extends StatefulWidget {
  const PicacgSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<PicacgSettings> createState() => _PicacgSettingsState();
}

class _PicacgSettingsState extends State<PicacgSettings> {
  bool showFrame = appdata.settings[5] == "1";
  bool punchIn = appdata.settings[6] == "1";
  bool useMyServer = appdata.settings[3] == "1";

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              title: Text("哔咔漫画".tr),
            ),
            if (!GetPlatform.isWeb)
              ListTile(
                leading: Icon(Icons.change_circle,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("使用转发服务器".tr),
                subtitle: Text("同时使用网络代理工具会减慢速度".tr),
                trailing: Switch(
                  value: useMyServer,
                  onChanged: (b) {
                    b ? appdata.settings[3] = "1" : appdata.settings[3] = "0";
                    setState(() {
                      useMyServer = b;
                    });
                    network.updateApi();
                    appdata.writeData();
                  },
                ),
                onTap: () {},
              ),
            ListTile(
              leading: Icon(Icons.hub_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("设置分流".tr),
              trailing: Select(
                initialValue: int.parse(appdata.appChannel)-1,
                values: [
                  "分流1".tr,
                  "分流2".tr,
                  "分流3".tr
                ],
                whenChange: (i){
                  appdata.appChannel = (i+1).toString();
                  appdata.writeData();
                  showMessage(Get.context, "正在获取分流IP".tr,time: 8);
                  network.updateApi().then((v)=>Get.closeAllSnackbars());
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.image, color: Theme.of(context).colorScheme.secondary),
              title: Text("设置图片质量".tr),
              trailing: Select(
                initialValue: appdata.getQuality()-1,
                values: [
                  "低".tr,
                  "中".tr,
                  "高".tr,
                  "原图".tr
                ],
                whenChange: (i){
                  appdata.setQuality(i+1);
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: Icon(Icons.manage_search_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              trailing: Select(
                initialValue: appdata.getSearchMode(),
                values: [
                  "新到书".tr,"旧到新".tr,"最多喜欢".tr,"最多指名".tr
                ],
                whenChange: (i){
                  appdata.setSearchMode(i);
                },
                inPopUpWidget: widget.popUp,
              ),
              title: Text("设置搜索及分类排序模式".tr),
            ),
            ListTile(
              leading: Icon(Icons.circle_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("显示头像框".tr),
              trailing: Switch(
                value: showFrame,
                onChanged: (b) {
                  b ? appdata.settings[5] = "1" : appdata.settings[5] = "0";
                  setState(() {
                    showFrame = b;
                  });
                  try {
                    var t = Get.find<InfoController>();
                    t.update();
                  }
                  catch(e){
                    //忽视
                  }
                  appdata.writeData();
                },
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.today, color: Theme.of(context).colorScheme.secondary),
              title: Text("启动时打卡".tr),
              onTap: () {},
              trailing: Switch(
                value: punchIn,
                onChanged: (b) {
                  b ? appdata.settings[6] = "1" : appdata.settings[6] = "0";
                  setState(() {
                    punchIn = b;
                  });
                  appdata.writeData();
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.collections_bookmark_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              trailing: Select(
                initialValue: int.parse(appdata.settings[30]),
                values: [
                  "旧到新".tr, "新到书".tr
                ],
                whenChange: (i){
                  appdata.settings[30] = i.toString();
                },
                inPopUpWidget: widget.popUp,
              ),
              title: Text("收藏夹漫画排序模式".tr),
            ),
          ],
        ));
  }
}
