import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/views/hitomi_views/hi_widgets.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:share_plus/share_plus.dart';
import '../../base.dart';
import '../../foundation/ui_mode.dart';
import '../show_image_page.dart';
import '../widgets/selectable_text.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class HitomiComicPageLogic extends GetxController{
  bool loading = true;
  HitomiComic? comic;
  String? message;
  var controller = ScrollController();
  bool showAppbarTitle = false;

  void get(String url, String name) async{
    var res = await HiNetwork().getComicInfo(url, name);
    if(res.error){
      message = res.errorMessage;
    }else{
      comic = res.data;
    }
    loading = false;
    update();
  }

  void refresh_() async{
    loading = true;
    comic = null;
    message = null;
    showAppbarTitle = false;
    controller = ScrollController();
    update();
  }
}

class HitomiComicPage extends StatelessWidget {
  const HitomiComicPage(this.comic, {Key? key}) : super(key: key);
  final HitomiComicBrief comic;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: GetBuilder<HitomiComicPageLogic>(
        init: HitomiComicPageLogic(),
        tag: comic.link,
        builder: (logic){
          if(logic.loading){
            logic.get(comic.link, comic.name);
            return showLoading(context);
          }else if(logic.comic == null){
            return showNetworkError(logic.message!, logic.refresh_, context);
          }else{
            logic.comic!;
            logic.controller = ScrollController();
            logic.controller.addListener(() {
              //检测当前滚动位置, 决定是否显示Appbar的标题
              bool temp = logic.showAppbarTitle;
              logic.showAppbarTitle = logic.controller.position.pixels>
                  boundingTextSize(
                      comic.name,
                      const TextStyle(fontSize: 22),
                      maxWidth: width
                  ).height+50;
              if(temp!=logic.showAppbarTitle) {
                logic.update();
              }
            });

            return CustomScrollView(
              controller: logic.controller,
              slivers: [
                SliverAppBar(
                  surfaceTintColor: logic.showAppbarTitle?null:Colors.transparent,
                  shadowColor: Colors.transparent,
                  title: AnimatedOpacity(
                    opacity: logic.showAppbarTitle?1.0:0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(comic.name),
                  ),
                  pinned: true,
                  actions: [
                    Tooltip(
                      message: "分享".tr,
                      child: IconButton(
                        icon: const Icon(Icons.share,),
                        onPressed: () {
                          Share.share(comic.name);
                        },
                      ),)
                  ],
                ),

                //标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectableTextCN(
                        text: comic.name,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),

                buildComicInfo(context, logic),

                //相关推荐
                const SliverToBoxAdapter(
                  child: Divider(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                          ),
                          Icon(Icons.recommend, color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(
                            width: 20,
                          ),
                          Text(
                            "相关推荐".tr,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                          )
                        ],
                      )),
                ),
                const SliverPadding(padding: EdgeInsets.all(5)),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.comic!.related.length, (context, i) {
                    return HitomiComicTileDynamicLoading(logic.comic!.related[i]);
                  }),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                SliverPadding(padding: MediaQuery.of(context).padding),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildComicInfo(BuildContext context, HitomiComicPageLogic logic) {
    if (UiMode.m1(context)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                //封面
                buildCover(context, 350, MediaQuery.of(context).size.width, logic),
                const SizedBox(
                  height: 20,
                ),
                ...buildInfoCards(logic, context),
              ],
            ),
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              //封面
              SizedBox(
                child: Column(
                  children: [
                    buildCover(context, 450, MediaQuery.of(context).size.width / 2, logic),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...buildInfoCards(logic, context),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  List<Widget> buildInfoCards(HitomiComicPageLogic logic, BuildContext context) {
    var res = <Widget>[];
    var res2 = <Widget>[];

    if (logic.comic!.artists != null && logic.comic!.artists!.isNotEmpty) {
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Text("作者".tr),
      ));
      res.add(Wrap(
        children: List.generate(logic.comic!.artists!.length,
                (index) => buildInfoCard(logic.comic!.artists![index], context)),
      ));
    }

    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("类型".tr),
    ));
    res.add(buildInfoCard(logic.comic!.type, context));

    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("发布时间"),
    ));
    res.add(buildInfoCard(logic.comic!.time, context, allowSearch: false));

    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("语言".tr),
    ));
    res.add(buildInfoCard(logic.comic!.lang, context, allowSearch: false));

    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("Tags"),
    ));

    res.add(Wrap(
      children: List.generate(logic.comic!.tags.length,
              (index) => buildInfoCard(logic.comic!.tags[index].name, context)),
    ));

    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => downloadComic(logic.comic!, context, comic.cover, comic.link),
              child: Text("下载".tr),
            ),
          ),
          SizedBox.fromSize(
            size: const Size(10, 1),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () => readHitomiComic(logic.comic!, comic.cover),
              child: Text("阅读".tr),
            ),
          ),

        ],
      ),
    ));
    return !UiMode.m1(context)?res+res2:res2+res;
  }

  Widget buildCover(BuildContext context, double height, double width, HitomiComicPageLogic logic) {
    return GestureDetector(
      onTap: () => Get.to(() => ShowImagePage(
        comic.cover,
      )),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
          child: CachedNetworkImage(
            width: width - 50,
            height: height,
            imageUrl: comic.cover,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )),
    );
  }

  Size boundingTextSize(String text, TextStyle style,  {int maxLines = 2^31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style), maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  Widget buildInfoCard(String title, BuildContext context, {bool allowSearch = true}) {
    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy,
                details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: Text("复制".tr),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制".tr);
                },
              ),
              PopupMenuItem(
                child: Text("添加到屏蔽词".tr),
                onTap: () {
                  appdata.blockingKeyword.add(title);
                  appdata.writeData();
                },
              ),
            ]);
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onSecondaryTapUp: (details) {
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy,
                    details.globalPosition.dx, details.globalPosition.dy),
                items: [
                  PopupMenuItem(
                    child: Text("复制".tr),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: (title)));
                      showMessage(context, "已复制".tr);
                    },
                  ),
                  PopupMenuItem(
                    child: Text("添加到屏蔽词".tr),
                    onTap: () {
                      appdata.blockingKeyword.add(title);
                      appdata.writeData();
                    },
                  ),
                ]);
          },
          onTap: allowSearch
              ? () => Get.to(() => HitomiSearchPage(title), preventDuplicates: false)
              : () {},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}

void downloadComic(HitomiComic comic, BuildContext context, String cover, String link){
  if(downloadManager.downloaded.contains(comic.id)){
    showMessage(context, "已下载".tr);
    return;
  }
  for(var i in downloadManager.downloading){
    if(i.id == comic.id){
      showMessage(context, "下载中".tr);
      return;
    }
  }
  downloadManager.addHitomiDownload(comic, cover, link);
  showMessage(context, "已加入下载".tr);
}