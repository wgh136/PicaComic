import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../base.dart';

Future<String?> getWindowsProxy() async{
  //手动设置的代理
  if(appdata.settings[8]!="0")  return appdata.settings[8];
  //只做了Windows端的自动检测
  //对于安卓, 大多数使用VPN进行代理, 无需设置代理地址
  //Web端流量走系统代理且无法进行设置
  if(!GetPlatform.isWindows)  return null;

  const channel = MethodChannel("kokoiro.xyz.pica_comic/proxy");
  var res = await channel.invokeMethod("getProxy");
  if(res == "No Proxy") return null;
  return res;
}

void setImageProxy() async{
  //Image加载使用的是Image.network()和CachedNetworkImage(), 均使用flutter内置http进行网络请求
  var proxy = await getWindowsProxy();
  if(proxy!=null) {
    HttpOverrides.global = WindowsProxyHttpOverrides(proxy);
  }
}

class WindowsProxyHttpOverrides extends HttpOverrides {
  String proxy;
  WindowsProxyHttpOverrides(this.proxy);
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => 'PROXY $proxy;';
    return client;
  }
}