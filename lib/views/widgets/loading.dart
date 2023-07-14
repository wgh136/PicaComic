import 'package:flutter/material.dart';
import 'package:get/get.dart';

Widget showLoading(BuildContext context, {bool withScaffold=false}){
  if(withScaffold){
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }else{
    return Center(
      child: SizedBox(
        width: 250,
        height: 80,
        child: Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16,),
            Center(
              child: Text("加载中".tr),
            ),
            const SizedBox(height: 4,),
            TextButton(onPressed: () => Get.back(), child: Text("取消".tr))
          ],
        ),
      ),
    );
  }
}