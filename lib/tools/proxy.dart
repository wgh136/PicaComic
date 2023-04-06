import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../base.dart';

Future<String?> getProxy() async{
  //手动设置的代理
  if(appdata.settings[8]!="0")  return appdata.settings[8];
  //对于安卓, 将获取WIFI设置中的代理
  //Web端流量走系统代理且无法进行设置
  if(GetPlatform.isWeb) return null;

  const channel = MethodChannel("kokoiro.xyz.pica_comic/proxy");
  var res = await channel.invokeMethod("getProxy");
  if(res == "No Proxy") return null;
  return res;
}

ProxyHttpOverrides? proxyHttpOverrides;

Future<void> setNetworkProxy() async{
  //Image加载使用的是Image.network()和CachedNetworkImage(), 均使用flutter内置http进行网络请求
  var proxy = await getProxy();
  if(kDebugMode){
    print("Set Proxy $proxy");
  }
  if(proxyHttpOverrides==null){
    proxyHttpOverrides = ProxyHttpOverrides(proxy);
    HttpOverrides.global = proxyHttpOverrides;
  }else{
    proxyHttpOverrides!.proxy = proxy;
  }
}

class ProxyHttpOverrides extends HttpOverrides {
  String? proxy;
  ProxyHttpOverrides(this.proxy);
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) => proxy==null ? "DIRECT" : 'PROXY $proxy;';
    client.badCertificateCallback = (X509Certificate cert, String host, int port)=>true;
    return client;
  }
}