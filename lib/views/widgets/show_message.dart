import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';

///显示消息
void showMessage(BuildContext? context, String message, {int time=2, bool useGet=true, Widget? action}){
  Get.closeCurrentSnackbar();
  if(useGet) {
    Get.showSnackbar(GetSnackBar(
      message: message,
      maxWidth: 350,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.fromLTRB(5, 5, 5, 16),
      animationDuration: const Duration(microseconds: 400),
      borderRadius: 10,
      duration: Duration(seconds: time),
      mainButton: action,
    ));
  }else{
    var padding = MediaQuery.of(Get.context!).size.width - 350;
    padding = padding>0?padding:0;
    ScaffoldMessenger.of(Get.context!).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(padding/2, 0, padding/2, 0),
    ));
  }
}

void hideMessage(BuildContext context){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}

void showDialogMessage(BuildContext context, String title, String message){
  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Get.back(), child: Text("了解".tl))
    ],
  ));
}

void showConfirmDialog(BuildContext context, String title, String content, void Function() onConfirm){
  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(onPressed: () => Get.back(), child: Text("取消".tl)),
      TextButton(onPressed: (){
        Get.back();
        onConfirm();
      }, child: Text("确认".tl)),
    ],
  ));
}