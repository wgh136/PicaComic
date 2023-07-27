import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';

///显示错误提示
Widget showNetworkError(String? message, void Function() retry, BuildContext context, {bool showBack=true}){
  return SafeArea(child: Stack(
    children: [
      if(showBack)
        Positioned(
          left: 8,
          top: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: ()=>Get.back(),
          ),
        ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Center(
          child: SizedBox(
            height: 170,
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60,),
                const SizedBox(height: 5,),
                Text(message??"网络错误", textAlign: TextAlign.center,),
                const SizedBox(height: 5,),
                FilledButton(onPressed: retry, child: Text('重试'.tl))
              ],
            ),
          ),
        ),
      )
    ],
  ));
}