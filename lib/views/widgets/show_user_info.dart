import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'avatar.dart';

void showUserInfo(BuildContext context, String? avatarUrl, String? frameUrl, String name, String? slogan, int level){
  showDialog(context: context, builder: (dialogContext){
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Avatar(size: 80,avatarUrl: avatarUrl,frame: frameUrl,),
              Text(name,style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              Text("Lv${level.toString()}"),
              const SizedBox(height: 10,width: 0,),
              SizedBox(width: 400,child: Align(
                alignment: Alignment.center,
                child: Text(slogan??"无".tr),
              ),)
            ],
          ),
        )
      ],
    );
  });
}