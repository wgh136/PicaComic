import 'package:flutter/material.dart';

class TabListener{
  TabController? controller;

  int getIndex(){
    if(controller != null){
      return controller!.index;
    }else{
      return 0;
    }
  }
}