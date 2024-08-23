import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../base.dart';
import '../foundation/app.dart';

///获取系统设置中的代理, 仅windows,安卓有效
Future<String?> getProxy() async{
  if(appdata.settings[58] == "1"){
    final file = File("${App.dataPath}/rule.json");
    var json = const JsonDecoder().convert(file.readAsStringSync());
    return "${InternetAddress.loopbackIPv4.address}:${json["port"]}";
  }

  //手动设置的代理
  if(appdata.settings[8].removeAllBlank=="") return null;
  if(appdata.settings[8]!="0")  return appdata.settings[8];
  //对于安卓, 将获取WIFI设置中的代理

  String res;
  if(!App.isLinux) {
    const channel = MethodChannel("kokoiro.xyz.pica_comic/proxy");
    try {
      res = await channel.invokeMethod("getProxy");
    }
    catch(e){
      return null;
    }
  }else{
    res = "No Proxy";
  }
  if(res == "No Proxy") return null;
  //windows上部分代理工具会将代理设置为http=127.0.0.1:8888;https=127.0.0.1:8888;ftp=127.0.0.1:7890的形式
  //下面的代码从中提取正确的代理地址
  if(res.contains("https")){
    var proxies = res.split(";");
    for (String proxy in proxies) {
      proxy = proxy.removeAllBlank;
      if (proxy.startsWith('https=')) {
        return proxy.substring(6);
      }
    }
  }
  // 执行最终检查
  final RegExp regex = RegExp(
    r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$',
    caseSensitive: false,
    multiLine: false,
  );
  if (!regex.hasMatch(res)) {
    return null;
  }

  return res;
}

ProxyHttpOverrides? proxyHttpOverrides;

///获取代理设置并应用
Future<void> setNetworkProxy() async{
  //Image加载使用的是Image.network()和CachedNetworkImage(), 均使用flutter内置http进行网络请求
  var proxy = await getProxy();

  if(proxy != null) {
    proxy = "PROXY $proxy;";
  }

  if(proxyHttpOverrides == null){
    proxyHttpOverrides = ProxyHttpOverrides(proxy);
    HttpOverrides.global = proxyHttpOverrides;
    Log.info("Network", "Set Proxy $proxy");
  } else if(proxyHttpOverrides!.proxy != proxy) {
    proxyHttpOverrides!.proxy = proxy;
    Log.info("Network", "Set Proxy $proxy");
  }
}

void setProxy(String? proxy){
  if(proxy != null) {
    proxy = "PROXY $proxy;";
  }
  var proxyHttpOverrides = ProxyHttpOverrides(proxy);
  HttpOverrides.global = proxyHttpOverrides;
}

class ProxyHttpOverrides extends HttpOverrides {
  String? proxy;
  ProxyHttpOverrides(this.proxy);

  String? get proxyStr => proxy?.replaceAll("PROXY", "").replaceAll(" ", "").replaceAll(";", "");

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 5);
    client.findProxy = (uri) => proxy??"DIRECT";
    client.idleTimeout = const Duration(seconds: 100);
    client.badCertificateCallback = (X509Certificate cert, String host, int port){
      if(host.contains("cdn"))  return true;
      final ipv4RegExp = RegExp(
          r'^((25[0-5]|2[0-4]\d|[0-1]?\d?\d)(\.(25[0-5]|2[0-4]\d|[0-1]?\d?\d)){3})$');
      if(ipv4RegExp.hasMatch(host)){
        // 允许ip访问
        return true;
      }
      return false;
    };
    return client;
  }
}