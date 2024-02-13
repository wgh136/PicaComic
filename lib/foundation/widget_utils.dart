import 'package:flutter/material.dart';

extension WidgetExtension on Widget{
  Widget padding(EdgeInsetsGeometry padding){
    return Padding(padding: padding, child: this);
  }

  Widget paddingLeft(double padding){
    return Padding(padding: EdgeInsets.only(left: padding), child: this);
  }

  Widget paddingRight(double padding){
    return Padding(padding: EdgeInsets.only(right: padding), child: this);
  }

  Widget paddingTop(double padding){
    return Padding(padding: EdgeInsets.only(top: padding), child: this);
  }

  Widget paddingBottom(double padding){
    return Padding(padding: EdgeInsets.only(bottom: padding), child: this);
  }

  Widget paddingAll(double padding){
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  Widget toCenter(){
    return Center(child: this);
  }

  Widget toAlign(AlignmentGeometry alignment){
    return Align(alignment: alignment, child: this);
  }
}