import 'package:flutter/material.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../tools/debug.dart';

extension WebviewExtension on WebViewController{
  Future<Map<String, String>?> getCookies(String url) async{
    if(url.contains("https://")){
      url.replaceAll("https://", "");
    }
    if(url[url.length-1] == '/'){
      url = url.substring(0, url.length-1);
    }
    final cookieManager = WebviewCookieManager();
    final cookies = await cookieManager.getCookies(url);
    log("$url\n$cookies");
    Map<String, String> res = {};
    for(var cookie in cookies){
      res[cookie.name] = cookie.value;
    }
    return res;
  }

  Future<String?> getUA() async{
    var res = await runJavaScriptReturningResult("navigator.userAgent");
    if(res is String){
      res = res.substring(1, res.length-1);
    }
    return res is String ? res : null;
  }
}

class AppWebview extends StatefulWidget {
  const AppWebview({required this.initialUrl, this.onDestroy, this.onTitleChange, super.key});

  final String initialUrl;

  final void Function(WebViewController)? onDestroy;

  final void Function(String title)? onTitleChange;

  @override
  State<AppWebview> createState() => _AppWebviewState();
}

class _AppWebviewState extends State<AppWebview> {
  late final WebViewController controller;

  String title = "Webview";

  bool loading = true;

  bool destroy = false;

  updateTitle() async{
    var newTitle = await controller.getTitle();
    if(destroy){
      return;
    }
    if(newTitle != null && newTitle != title && newTitle != ""){
      if(mounted){
        setState(() {
          title = newTitle;
        });
      }
      widget.onTitleChange?.call(title);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    updateTitle();
  }

  @override
  void initState() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (s){
            if(mounted){
              setState(() {
                loading = false;
              });
            }
          }
        ),
      )..loadRequest(Uri.parse(widget.initialUrl));
    super.initState();
    updateTitle();
  }

  @override
  void dispose() {
    destroy = true;
    widget.onDestroy?.call(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,),),
      body: loading ? const Center(child: CircularProgressIndicator(),) :
        WebViewWidget(controller: controller,)
    );
  }
}

