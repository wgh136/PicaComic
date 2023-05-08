import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../base.dart';
import '../widgets/widgets.dart';

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
    showMessage(Get.context, "正在获取分流IP",time: 8);
    network.updateApi().then((v)=>Get.closeAllSnackbars());
    update();
  }
}

class ModeRadioLogic2 extends GetxController{
  int value = appdata.getSearchMode();
  void change(int i){
    value = i;
    appdata.setSearchMode(i);
    update();
  }
}

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