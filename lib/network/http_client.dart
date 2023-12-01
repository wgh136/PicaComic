import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../base.dart';
import '../foundation/app.dart';

///获取系统设置中的代理, 仅windows,安卓有效
Future<String?> getProxy() async{
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

  LogManager.addLog(LogLevel.info, "Network", "Set Proxy $proxy");
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

  String? get proxyStr => proxy?.replaceAll("PROXY", "").replaceAll(" ", "").replaceAll(";", "");

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = AppHttpClient(super.createHttpClient(context));
    client.connectionTimeout = const Duration(seconds: 5);
    client.findProxy = (uri) => proxy??"DIRECT";
    client.badCertificateCallback = (X509Certificate cert, String host, int port)=>true;
    return client;
  }
}

class AppHttpClient implements HttpClient{
  AppHttpClient(this.client);

  final HttpClient client;

  @override
  bool autoUncompress = true;

  @override
  Duration? connectionTimeout;

  @override
  Duration idleTimeout = const Duration(seconds: 10);

  @override
  int? maxConnectionsPerHost;

  @override
  String? userAgent;

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    client.addCredentials(url, realm, credentials);
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    client.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set authenticate(Future<bool> Function(Uri url, String scheme, String? realm)? f) {
    client.authenticate = f;
  }

  @override
  set authenticateProxy(Future<bool> Function(String host, int port, String scheme, String? realm)? f) {
    client.authenticateProxy = f;
  }

  @override
  set badCertificateCallback(bool Function(X509Certificate cert, String host, int port)? callback) {
    client.badCertificateCallback = callback;
  }

  @override
  void close({bool force = false}) {
    client.close();
  }

  @override
  set connectionFactory(Future<ConnectionTask<Socket>> Function(Uri url, String? proxyHost, int? proxyPort)? f) {
    client.connectionFactory = f;
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return client.delete(host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return client.deleteUrl(url);
  }

  @override
  set findProxy(String Function(Uri url)? f) {
    client.findProxy = f;
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return client.get(host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return client.getUrl(url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return client.head(host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return client.headUrl(url);
  }

  @override
  set keyLog(Function(String line)? callback) {
    client.keyLog = callback;
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) {
    return client.open(method, host, port, path);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if(appdata.settings[58] == "0"){
      return client.openUrl(method, url);
    }
    if(!File("${App.dataPath}/hosts.json").existsSync()){
      return client.openUrl(method, url);
    }
    var config = const JsonDecoder().convert(File("${App.dataPath}/hosts.json").readAsStringSync());
    if(config["https"][url.host] != null){
      url = Uri.parse(url.toString().replaceFirst(url.host, config["https"][url.host]));
    } else if(config["http"][url.host] != null){
      url = Uri.parse(url.toString().replaceFirst(url.host, config["http"][url.host])
          .replaceFirst("https://", "http://"));
    }
    return client.openUrl(method, url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return client.patch(host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return client.patchUrl(url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return client.post(host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return client.postUrl(url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return client.put(host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return client.putUrl(url);
  }

}
