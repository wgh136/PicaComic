import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:flutter/material.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image/image.dart' as image;
import '../../foundation/ui_mode.dart';


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
    Map<String, String> res = {};
    for(var cookie in cookies){
      res[cookie.name] = cookie.value;
    }
    return res;
  }

  Future<String?> getUA() async{
    var res = await runJavaScriptReturningResult("navigator.userAgent");
    if(res is String){
      if(res[0] == "'" || res[0] == "\"") {
        res = res.substring(1, res.length-1);
      }
    }
    return res is String ? res : null;
  }
}

class AppWebview extends StatefulWidget {
  const AppWebview({required this.initialUrl, this.onDestroy, this.onTitleChange, this.onNavigation, this.singlePage = false, super.key});

  final String initialUrl;

  final void Function(WebViewController)? onDestroy;

  final void Function(String title)? onTitleChange;

  final bool Function(String url)? onNavigation;

  final bool singlePage;

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

  Future<List<String>> _androidFilePicker(FileSelectorParams params) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery);

    if (photo == null) {
      return [];
    }

    final imageData = await photo.readAsBytes();
    final decodedImage = image.decodeImage(imageData)!;
    final scaledImage = image.copyResize(decodedImage, width: 500);
    final jpg = image.encodeJpg(scaledImage, quality: 90);

    final filePath = (await getTemporaryDirectory()).uri.resolve(
      './image_${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    final file = await File.fromUri(filePath).create(recursive: true);
    await file.writeAsBytes(jpg, flush: true);

    return [file.uri.toString()];
  }

  @override
  void initState(){
    super.initState();
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
          },
          onNavigationRequest: (request){
            var res = widget.onNavigation?.call(request.url) ?? false;
            if(!request.url.isURL){
              return NavigationDecision.prevent;
            }
            if(res) {
              return NavigationDecision.prevent;
            } else {
              return NavigationDecision.navigate;
            }
          }
        ),
      )..loadRequest(Uri.parse(widget.initialUrl));
    if (Platform.isAndroid) {
      final androidController = controller.platform as AndroidWebViewController;
      androidController.setOnShowFileSelector(_androidFilePicker);
    }
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
                onTap: () async => launchUrlString((await controller.currentUrl())!),
              ),
              PopupMenuItem(
                child: Text("复制链接".tl),
                onTap: () async => Clipboard.setData(ClipboardData(text: (await controller.currentUrl())!)),
              ),
              PopupMenuItem(
                child: Text("重新加载".tl),
                onTap: () => controller.reload(),
              ),
            ]);
          },
        ),
      )
    ];

    Widget body = loading ? const Center(child: CircularProgressIndicator(),) :
    WebViewWidget(controller: controller,);

    if(useCustomAppBar){
      body = Column(
        children: [
          CustomAppbar(
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

