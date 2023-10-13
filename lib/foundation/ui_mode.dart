import 'package:flutter/cupertino.dart';
import 'app.dart' as app;

class UiMode{
  static bool m1(BuildContext context){
    return app.App.uiMode(context) == app.UiModes.m1;
  }

  static bool m2(BuildContext context){
    return app.App.uiMode(context) == app.UiModes.m2;
  }

  static bool m3(BuildContext context){
    return app.App.uiMode(context) == app.UiModes.m3;
  }
}