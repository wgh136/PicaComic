import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16,),
            Center(
              child: Text("加载中".tl),
            ),
            const SizedBox(height: 4,),
            TextButton(onPressed: () => Navigator.pop(context), child: Text("取消".tl))
          ],
        ),
      ),
    );
  }
}

void showLoadingDialog(BuildContext context, void Function() onCancel){
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          child: Container(
            width: 100,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(width: 16,),
                const Text('Loading', style: TextStyle(fontSize: 16),),
                const Spacer(),
                TextButton(onPressed: () {
                  Get.back();
                  onCancel();
                }, child: Text("取消".tl))
              ],
            ),
          ),
        ),
      );
    },
  );
}