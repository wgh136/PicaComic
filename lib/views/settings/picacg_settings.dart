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
  int value = appdata.getSearchMod();
  void change(int i){
    value = i;
    appdata.saveSearchMode(i);
    update();
  }
}
