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

  Widget paddingVertical(double padding){
    return Padding(padding: EdgeInsets.symmetric(vertical: padding), child: this);
  }

  Widget paddingHorizontal(double padding){
    return Padding(padding: EdgeInsets.symmetric(horizontal: padding), child: this);
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

  Widget sliverPadding(EdgeInsetsGeometry padding){
    return SliverPadding(padding: padding, sliver: this);
  }

  Widget sliverPaddingAll(double padding){
    return SliverPadding(padding: EdgeInsets.all(padding), sliver: this);
  }

  Widget sliverPaddingVertical(double padding){
    return SliverPadding(padding: EdgeInsets.symmetric(vertical: padding), sliver: this);
  }

  Widget sliverPaddingHorizontal(double padding){
    return SliverPadding(padding: EdgeInsets.symmetric(horizontal: padding), sliver: this);
  }

  Widget toSliver(){
    return SliverToBoxAdapter(child: this);
  }

  Widget fixWidth(double width){
    return SizedBox(width: width, child: this);
  }

  Widget fixHeight(double height){
    return SizedBox(height: height, child: this);
  }
}

extension ContextExt on BuildContext {
  EdgeInsets get padding => MediaQuery.of(this).padding;

  double get width => MediaQuery.of(this).size.width;

  double get height => MediaQuery.of(this).size.height;

  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;
}