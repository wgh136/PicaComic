import 'package:get/get.dart';
import 'package:flutter/material.dart';

///显示消息
void showMessage(context, String message, {int time=2, bool useGet=true}){
  Get.closeCurrentSnackbar();
  if(useGet) {
    Get.showSnackbar(GetSnackBar(
      message: message,
      maxWidth: 350,
      snackStyle: SnackStyle.FLOATING,
      margin: const EdgeInsets.all(5),
      animationDuration: const Duration(microseconds: 400),
      borderRadius: 10,
      duration: Duration(seconds: time),
    ));
  }else{
    var padding = MediaQuery.of(context).size.width - 350;
    padding = padding>0?padding:0;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(padding/2, 0, padding/2, 0),
    ));
  }
}

void hideMessage(context){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}