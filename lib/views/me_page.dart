import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/eh_views/subscription.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../tools/debug.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'jm_views/jm_comic_page.dart';
import 'main_page.dart';
import 'package:pica_comic/tools/extensions.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (!UiMode.m1(context))
          const SliverPadding(padding: EdgeInsets.all(30)),
        SliverToBoxAdapter(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: const Size(400, 120),
                  child: const Center(
                    child: Text(
                      "Pica Comic",
                      style: TextStyle(
                          fontFamily: "font2",
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Wrap(
                  children: [
                    MePageButton(
                      title: "账号管理".tl,
                      subTitle: "查看或修改账号信息".tl,
                      icon: Icons.switch_account,
                      onTap: () => showAdaptiveWidget(App.globalContext!,
                          AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,)),
                    ),
                    MePageButton(
                      title: "收藏夹".tl,
                      subTitle: "查看已收藏的漫画".tl,
                      icon: Icons.bookmarks,
                      onTap: () => MainPage.to(() => const AllFavoritesPage()),
                    ),
                    MePageButton(
                      title: "已下载".tl,
                      subTitle: "管理已下载的漫画".tl,
                      icon: Icons.download_for_offline,
                      onTap: () => MainPage.to(() => const DownloadPage()),
                    ),
                    MePageButton(
                      title: "历史记录".tl,
                      subTitle: "查看历史记录".tl,
                      icon: Icons.history,
                      onTap: () => MainPage.to(() => const HistoryPage()),
                    ),
                    MePageButton(
                      title: "工具".tl,
                      subTitle: "使用工具发现更多漫画".tl,
                      icon: Icons.construction,
                      onTap: openTool,
                    ),
                    if(kDebugMode)
                    MePageButton(
                      title: "Debug",
                      subTitle: "",
                      icon: Icons.bug_report,
                      onTap: () => debug(),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  void openTool(){
    showModalBottomSheet(context: App.globalContext!, builder: (context) => Column(
      children: [
        ListTile(title: Text("工具".tl),),
        ListTile(
          leading: const Icon(Icons.subscriptions),
          title: Text("EH订阅".tl),
          onTap: () {
            App.globalBack();
            MainPage.to(() => const SubscriptionPage());
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search_outlined),
          title: Text("图片搜索 [搜图bot酱]".tl),
          onTap: () async{
            App.globalBack();
            if(Platform.isAndroid || Platform.isIOS) {
              MainPage.to(() => AppWebview(
                initialUrl: "https://soutubot.moe/",
                onNavigation: (uri){
                  return handleAppLinks(Uri.parse(uri), showMessageWhenError: false);
                },
              ),);
            }else{
              var webview = FlutterWindowsWebview();
              webview.launchWebview(
                "https://soutubot.moe/",
                WebviewOptions(
                  onNavigation: (uri){
                    if(handleAppLinks(Uri.parse(uri), showMessageWhenError: false)){
                      Future.microtask(() => webview.close());
                      return true;
                    }
                    return false;
                  }
                )
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search),
          title: Text("图片搜索 [SauceNAO]".tl),
          onTap: () async{
            App.globalBack();
            if(Platform.isAndroid || Platform.isIOS) {
              MainPage.to(() => AppWebview(
                initialUrl: "https://saucenao.com/",
                onNavigation: (uri){
                  return handleAppLinks(Uri.parse(uri), showMessageWhenError: false);
                },
              ),);
            }else{
              var webview = FlutterWindowsWebview();
              webview.launchWebview(
                  "https://saucenao.com/",
                  WebviewOptions(
                      onNavigation: (uri){
                        if(handleAppLinks(Uri.parse(uri), showMessageWhenError: false)){
                          Future.microtask(() => webview.close());
                          return true;
                        }
                        return false;
                      }
                  )
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.web),
          title: Text("打开链接".tl),
          onTap: (){
            App.globalBack();
            showDialog(context: App.globalContext!, builder: (context) {
              final controller = TextEditingController();

              validateText() {
                var text = controller.text;
                if(text == ""){
                  return null;
                }

                if(!text.contains("http://") && !text.contains("https://")){
                  text = "https://$text";
                }

                if(!text.isURL){
                  return "不支持的链接".tl;
                }
                var uri = Uri.parse(text);
                if(!["exhentai.org", "e-hentai.org", "hitomi.la",
                  "nhentai.net", "nhentai.xxx"].contains(uri.host)){
                  return "不支持的链接".tl;
                }
                return null;
              }

              void Function(void Function())? stateSetter;

              onFinish(){
                if(validateText() != null){
                  stateSetter?.call((){});
                }else{
                  App.globalBack();
                  var text = controller.text;
                  if(!text.contains("http://") && !text.contains("https://")){
                    text = "https://$text";
                  }
                  handleAppLinks(Uri.parse(text));
                }
              }

              return AlertDialog(
                title: Text("输入链接".tl),
                content: StatefulBuilder(
                  builder: (BuildContext context, void Function(void Function()) setState) {
                    stateSetter = setState;
                    return TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        errorText: validateText(),
                      ),
                      onSubmitted: (s) => onFinish(),
                    );
                  },
                ),
                actions: [
                  TextButton(onPressed: onFinish, child: Text("打开".tl)),
                ],
              );
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text("禁漫漫画ID".tl),
          onTap: (){
            App.globalBack();
            var controller = TextEditingController();
            showDialog(context: context, builder: (context){
              return AlertDialog(
                title: Text("输入禁漫漫画ID".tl),
                content: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                    onEditingComplete: () {
                      App.globalBack();
                      if(controller.text.isNum){
                        MainPage.to(()=>JmComicPage(controller.text));
                      }else{
                        showMessage(App.globalContext, "输入的ID不是数字".tl);
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "ID",
                        prefix: Text("JM")
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: (){
                    App.globalBack();
                    if(controller.text.isNum){
                      MainPage.to(()=>JmComicPage(controller.text));
                    }else{
                      showMessage(App.globalContext, "输入的ID不是数字".tl);
                    }
                  }, child: Text("提交".tl))
                ],
              );
            });
          },
        )
      ],
    ));
  }
}

class MePageButton extends StatefulWidget {
  const MePageButton({required this.title, required this.subTitle, required this.icon, required this.onTap, super.key});

  final String title;
  final String subTitle;
  final IconData icon;
  final void Function() onTap;

  @override
  State<MePageButton> createState() => _MePageButtonState();
}

class _MePageButtonState extends State<MePageButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    double width;
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = 10.0;
    if (screenWidth > changePoint2) {
      screenWidth -= 400;
      width = screenWidth / 2 - padding * 2;
    } else if (screenWidth > changePoint) {
      screenWidth -= 80;
      width = screenWidth / 2 - padding * 2;
    } else {
      width = screenWidth - padding * 2;
    }

    if (width > 400) {
      width = 400;
    }
    var height = width / 3;
    if(height < 100){
      height = 100;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: widget.onTap,
            child: SizedBox(
              width: width,
              height: height,
              child: AnimatedContainer(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    color: hovering?Theme.of(context).colorScheme.inversePrimary.withAlpha(150):Theme.of(context).colorScheme.inversePrimary.withAlpha(40)
                ),
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.subTitle, style: const TextStyle(fontSize: 15),),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipPath(
                          clipper: MePageIconClipper(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: hovering?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surface,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(widget.icon, color: hovering?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface,),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MePageIconClipper extends CustomClipper<Path>{
  @override
  Path getClip(Size size) {
    final path = Path();
    final r = size.width * 0.3; // 控制弧线的大小

    // 起始点
    path.moveTo(r, 0);

    // 上边弧线
    path.arcToPoint(
      Offset(size.width - r, 0),
      radius: Radius.circular(r * 2),
      clockwise: false,
    );

    // 右上角圆弧
    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 右边弧线
    path.arcToPoint(
      Offset(size.width, size.height - r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 右下角圆弧
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 下边弧线
    path.arcToPoint(
      Offset(r, size.height),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左下角圆弧
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 左边弧线
    path.arcToPoint(
      Offset(0, r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左上角圆弧
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }

}