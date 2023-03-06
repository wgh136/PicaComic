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
    return SafeArea(child: Stack(
      children: [
        Positioned(
          left: 8,
          top: 8,
          child: IconButton(
            iconSize: 24,
            icon: const Icon(Icons.arrow_back,),
            onPressed: ()=>Get.back(),
          ),
        ),
        const Center(child: CircularProgressIndicator(),)
      ],
    ));
  }
}