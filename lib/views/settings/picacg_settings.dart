import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../base.dart';
import '../me_page.dart';
import '../widgets/select.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

void setCloudflareIp(BuildContext context) {
  showDialog(
      context: context,
      builder: (dialogContext) => GetBuilder<SetCloudFlareIpController>(
          init: SetCloudFlareIpController(),
          builder: (logic) => SimpleDialog(
            title: const Text("Cloudflare IP"),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 15, 6, 15),
                  color: Colors.yellow,
                  child: Row(
                    children: const [
                      Icon(Icons.warning),
                      SizedBox(
                        width: 5,
                      ),
                      Expanded(
                        child: Text(
                          "使用Cloudflare IP访问无法进行https请求, 可能存在风险. 为确保密码安全, 登录时将无视此设置",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                title: const Text("不使用"),
                trailing: Radio<String>(
                  value: "0",
                  groupValue: logic.value,
                  onChanged: (value) => logic.setValue(value!),
                ),
              ),
              ListTile(
                title: const Text("使用哔咔官方提供的IP"),
                trailing: Radio<String>(
                  value: "1",
                  groupValue: logic.value,
                  onChanged: (value) => logic.setValue(value!),
                ),
              ),
              ListTile(
                title: const Text("自定义"),
                trailing: Radio<String>(
                  value: "2",
                  groupValue: (logic.value != "0" && logic.value != "1") ? "2" : "-1",
                  onChanged: (value) => logic.setValue(value!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                child: TextField(
                  enabled: logic.value != "0" && logic.value != "1",
                  controller: logic.controller,
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: logic.value == "2" ? "输入一个Cloudflare CDN Ip" : ""),
                ),
              ),
              Center(
                child: FilledButton(
                  child: const Text("确认"),
                  onPressed: () => logic.submit(),
                ),
              )
            ],
          )));
}

class SetCloudFlareIpController extends GetxController {
  var value = appdata.settings[15];
  late var controller = TextEditingController(text: (value != "0" && value != "1") ? value : "");
  void setValue(String s) {
    value = s;
    update();
  }

  void submit() {
    appdata.settings[15] = (value != "0" && value != "1") ? controller.text : value;
    appdata.writeData();
    Get.back();
    network.updateApi();
  }
}

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
            const ListTile(
              title: Text("哔咔漫画"),
            ),
            if (!GetPlatform.isWeb)
              ListTile(
                leading: Icon(Icons.change_circle,
                    color: Theme.of(context).colorScheme.secondary),
                title: const Text("使用转发服务器"),
                subtitle: const Text("同时使用网络代理工具会减慢速度"),
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
              title: const Text("设置分流"),
              trailing: Select(
                initialValue: int.parse(appdata.appChannel)-1,
                values: const [
                  "分流1",
                  "分流2",
                  "分流3"
                ],
                whenChange: (i){
                  appdata.appChannel = (i+1).toString();
                  appdata.writeData();
                  showMessage(Get.context, "正在获取分流IP",time: 8);
                  network.updateApi().then((v)=>Get.closeAllSnackbars());
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading:
              Icon(Icons.device_hub, color: Theme.of(context).colorScheme.secondary),
              title: const Text("Cloudflare IP"),
              trailing: const Icon(
                Icons.arrow_right,
              ),
              onTap: () {
                setCloudflareIp(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.image, color: Theme.of(context).colorScheme.secondary),
              title: const Text("设置图片质量"),
              trailing: Select(
                initialValue: appdata.getQuality()-1,
                values: const [
                  "低",
                  "中",
                  "高",
                  "原图"
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
                values: const [
                  "新书在前","旧书在前","最多喜欢","最多指名"
                ],
                whenChange: (i){
                  appdata.setSearchMode(i);
                },
                inPopUpWidget: widget.popUp,
              ),
              title: const Text("设置搜索及分类排序模式"),
            ),
            ListTile(
              leading: Icon(Icons.circle_outlined,
                  color: Theme.of(context).colorScheme.secondary),
              title: const Text("显示头像框"),
              trailing: Switch(
                value: showFrame,
                onChanged: (b) {
                  b ? appdata.settings[5] = "1" : appdata.settings[5] = "0";
                  setState(() {
                    showFrame = b;
                  });
                  var t = Get.find<InfoController>();
                  t.update();
                  appdata.writeData();
                },
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.today, color: Theme.of(context).colorScheme.secondary),
              title: const Text("启动时打卡"),
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
          ],
        ));
  }
}
