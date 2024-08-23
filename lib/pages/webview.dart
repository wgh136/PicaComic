import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/components/components.dart';
export 'package:flutter_inappwebview/flutter_inappwebview.dart' show WebUri, URLRequest;

extension WebviewExtension on InAppWebViewController{
  Future<Map<String, String>?> getCookies(String url) async{
    if(url.contains("https://")){
      url.replaceAll("https://", "");
    }
    if(url[url.length-1] == '/'){
      url = url.substring(0, url.length-1);
    }
    CookieManager cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri(url));
    Map<String, String> res = {};
    for(var cookie in cookies){
      res[cookie.name] = cookie.value;
    }
    return res;
  }

  Future<String?> getUA() async{
    var res = await evaluateJavascript(source: "navigator.userAgent");
    if(res is String){
      if(res[0] == "'" || res[0] == "\"") {
        res = res.substring(1, res.length-1);
      }
    }
    return res is String ? res : null;
  }
}

class AppWebview extends StatefulWidget {
  const AppWebview({required this.initialUrl, this.onTitleChange,
    this.onNavigation, this.singlePage = false, this.onStarted, super.key});

  final String initialUrl;

  final void Function(String title, InAppWebViewController controller)? onTitleChange;

  final bool Function(String url)? onNavigation;

  final void Function(InAppWebViewController controller)? onStarted;

  final bool singlePage;

  @override
  State<AppWebview> createState() => _AppWebviewState();
}

class _AppWebviewState extends State<AppWebview> {
  InAppWebViewController? controller;

  String title = "Webview";

  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    bool useCustomAppBar = !UiMode.m1(context) && !widget.singlePage;

    final actions = [
      Tooltip(
        message: "More",
        child: IconButton(
          icon: const Icon(Icons.more_horiz),
          onPressed: (){
            showMenu(context: context, position: RelativeRect.fromLTRB(
                MediaQuery.of(context).size.width,
                0,
                MediaQuery.of(context).size.width,
                0
            ), items: [
              PopupMenuItem(
                child: Text("在浏览器中打开".tl),
                onTap: () async => launchUrlString((await controller?.getUrl())!.path),
              ),
              PopupMenuItem(
                child: Text("复制链接".tl),
                onTap: () async => Clipboard.setData(ClipboardData(text: (await controller?.getUrl())!.path)),
              ),
              PopupMenuItem(
                child: Text("重新加载".tl),
                onTap: () => controller?.reload(),
              ),
            ]);
          },
        ),
      )
    ];

    Widget body = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      onTitleChanged: (c, t){
        if(mounted){
          setState(() {
            title = t ?? "Webview";
          });
        }
        widget.onTitleChange?.call(title, controller!);
      },
      shouldOverrideUrlLoading: (c, r) async {
        var res = widget.onNavigation?.call(r.request.url?.toString() ?? "") ?? false;
        if(res) {
          return NavigationActionPolicy.CANCEL;
        } else {
          return NavigationActionPolicy.ALLOW;
        }
      },
      onWebViewCreated: (c){
        controller = c;
        widget.onStarted?.call(c);
      },
      onProgressChanged: (c, p){
        if(mounted){
          setState(() {
            _progress = p / 100;
          });
        }
      },
    );

    body = Stack(
      children: [
        Positioned.fill(child: body),
        if(_progress < 1.0)
          const Positioned.fill(child: Center(
              child: CircularProgressIndicator()))
      ],
    );

    if(useCustomAppBar){
      body = Column(
        children: [
          Appbar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,),
            actions: actions,
          ),
          Expanded(child: body)
        ],
      );
    }

    return Scaffold(
      appBar: !useCustomAppBar ? AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,),
        actions: actions,
      ) : null,
      body: body
    );
  }
}

class MacWebview extends InAppBrowser {
  final void Function(
      InAppWebViewController controller,
      InAppBrowser brower
    )? onStarted;

  final void Function(
      String? title,
      InAppWebViewController controller,
      InAppBrowser brower
      )? onTitleChange;

  final void Function()? onClose;

  MacWebview({this.onStarted, this.onTitleChange, this.onClose}) : super();

  @override
  void onBrowserCreated() {
    onStarted?.call(webViewController!, this);
    super.onBrowserCreated();
  }

  @override
  void onTitleChanged(String? title) {
    onTitleChange?.call(title, webViewController!, this);
    super.onTitleChanged(title);
  }

  @override
  void onExit() {
    onClose?.call();
    super.onExit();
  }
}
