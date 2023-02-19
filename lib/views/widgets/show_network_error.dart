import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';

Widget showNetworkError(BuildContext context, void Function() retry){
  return Stack(
    children: [
      Positioned(top: 0,
        left: 0,child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),child: Tooltip(
          message: "返回",
          child: IconButton(
            iconSize: 25,
            icon: const Icon(Icons.arrow_back_outlined),
            onPressed: (){Get.back();},
          ),
        ),),
      ),
      Positioned(
        top: MediaQuery.of(context).size.height/2-80,
        left: 0,
        right: 0,
        child: const Align(
          alignment: Alignment.topCenter,
          child: Icon(Icons.error_outline,size:60,),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height/2-10,
        child: Align(
          alignment: Alignment.topCenter,
          child: network.status?Text(network.message):const Text("网络错误"),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height/2+30,
        child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 100,
              height: 40,
              child: FilledButton(
                onPressed: (){
                  retry();
                },
                child: const Text("重试"),
              ),
            )
        ),
      ),
    ],
  );
}