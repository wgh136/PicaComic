import '../../base.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

///设置分类中漫画排序模式, 返回设置是否发生变化
Future<bool> setJmComicsOrder(BuildContext context) async{
  var mode = appdata.settings[16];
  await showDialog(context: context, builder: (dialogContext){
    return SimpleDialog(
      title: const Text("设置漫画排序模式"),
      children: [
        GetBuilder<SetJmComicsOrderController>(
          init: SetJmComicsOrderController(),
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
                    title: const Text("总排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "1",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("1"),
                  ),
                  ListTile(
                    title: const Text("月排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "2",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("2"),
                  ),
                  ListTile(
                    title: const Text("周排行"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "3",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("3"),
                  ),
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
  return appdata.settings[16] == mode;
}

class SetJmComicsOrderController extends GetxController{
  String value = appdata.settings[16];

  void set(String v){
    value = v;
    appdata.settings[16] = v;
    appdata.writeData();
    Get.back();
  }
}

void setJmImageShut(BuildContext context) async{
  showDialog(context: context, builder: (context){
    return SimpleDialog(
      title: const Text("设置图片分流"),
      children: [
        GetBuilder(
          init: SetJmImageShutController(),
          builder: (logic){
            return SizedBox(
              width: 400,
              child: Column(
                children: [
                  ListTile(
                    title: const Text("分流1"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "0",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("0"),
                  ),
                  ListTile(
                    title: const Text("分流2"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "1",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("1"),
                  ),
                  ListTile(
                    title: const Text("分流3"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "2",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("2"),
                  ),
                  ListTile(
                    title: const Text("分流4"),
                    trailing: Radio<String>(
                      groupValue: logic.value,
                      value: "3",
                      onChanged: (v)=>logic.set(v!),
                    ),
                    onTap: ()=>logic.set("3"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  });
}

class SetJmImageShutController extends GetxController{
  var value = appdata.settings[17];

  void set(String s){
    value = s;
    appdata.settings[17] = s;
    appdata.writeData();
    jmNetwork.updateApi();
    jmNetwork.loginFromAppdata();
    update();
  }
}