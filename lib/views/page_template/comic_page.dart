import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:share_plus/share_plus.dart';
import '../../base.dart';
import '../../foundation/ui_mode.dart';
import '../../network/res.dart';
import '../show_image_page.dart';
import '../widgets/list_loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/show_message.dart';

@immutable
class EpsData{
  /// episodes text
  final List<String> eps;

  /// callback when a episode button is tapped
  final void Function(int) onTap;

  /// comic episode data
  const EpsData(this.eps, this.onTap);
}

class ThumbnailsData{
  List<String> thumbnails;
  int current = 1;
  final int maxPage;
  final Future<Res<List<String>>> Function(int page) load;

  Future<void> get(void Function() update) async{
    if(current >= maxPage) {
      return;
    }
    var res = await load(current+1);
    if(res.success){
      thumbnails.addAll(res.data);
      current++;
      update();
    }
  }

  ThumbnailsData(this.thumbnails, this.load, this.maxPage);
}

class ComicPageLogic<T extends Object> extends GetxController{
  bool loading = true;
  T? data;
  String? message;
  bool showAppbarTitle = false;
  ScrollController controller = ScrollController();
  ThumbnailsData? thumbnailsData;

  void get(Future<Res<T>> Function() loadData) async{
    var res = await loadData();
    if(res.error){
      message = res.errorMessage;
    }else{
      data = res.data;
    }
    loading = false;
    update();
  }

  void refresh_(){
    data = null;
    message = null;
    loading = true;
    update();
  }
}

abstract class ComicPage<T extends Object> extends StatelessWidget{
  /// comic info page, show comic's detailed information,
  /// and allow user download or read comic.
  const ComicPage({super.key});

  ComicPageLogic<T> get _logic => Get.find<ComicPageLogic<T>>(tag: tag);

  /// title
  String? get title;

  /// tags
  Map<String, List<String>>? get tags;

  /// load comic data
  Future<Res<T>> loadData();

  /// get comic data
  T? get data => _logic.data;

  /// tag, used by Get, creating a GetxController.
  ///
  /// This should be a unique identifier,
  /// to prevent loading same data when user open more than one comic page.
  String get tag;

  /// comic total page
  ///
  /// when not null, it will be display at the end of the title.
  int? get pages;

  /// link to comic cover.
  String get cover;

  /// callback when user tap on a tag
  void tapOnTags(String tag);

  /// actions for comic, such as like, favorite, comment
  Row? get actions;

  FilledButton get downloadButton;

  FilledButton get readButton;

  /// display uploader info
  Card? get uploaderInfo;

  /// episodes information
  EpsData? get eps;

  /// comic introduction
  String? get introduction;

  /// create thumbnails data
  ThumbnailsData? get thumbnailsCreator;

  ThumbnailsData? get thumbnails => _logic.thumbnailsData;

  SliverGrid? recommendationBuilder(T data);

  /// update widget state
  void update() => _logic.update();

  /// get context
  BuildContext get context => Get.context!;

  /// interface for building more info widget
  Widget? get buildMoreInfo => null;

  /// translation tags to CN
  bool get enableTranslationToCN => false;

  @override
  Widget build(BuildContext context){
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: GetBuilder<ComicPageLogic<T>>(
        tag: tag,
        initState: (logic){
          Get.put(ComicPageLogic<T>(), tag: tag);
        },
        dispose: (logic){
          Get.delete<ComicPageLogic<T>>(tag: tag);
        },
        builder: (logic){
          if(logic.loading){
            logic.get(loadData);
            return showLoading(context);
          }else if(logic.message != null){
            return showNetworkError(logic.message, logic.refresh_, context);
          }else{
            _logic.thumbnailsData ??= thumbnailsCreator;
            logic.controller = ScrollController();
            logic.controller.addListener(() {
              bool temp = logic.showAppbarTitle;
              if (!logic.controller.hasClients) {
                return;
              }
              logic.showAppbarTitle = logic.controller.position.pixels >
                  boundingTextSize(title!,
                      const TextStyle(fontSize: 22),
                      maxWidth: width)
                      .height +
                      50;
              if (temp != logic.showAppbarTitle) {
                logic.update();
              }
            });
            return CustomScrollView(
              controller: logic.controller,
              slivers: [
                ...buildTitle(logic),
                buildComicInfo(logic, context),
                ...buildEpisodeInfo(context),
                ...buildIntroduction(context),
                ...buildThumbnails(context),
                ...buildRecommendation(context),
                SliverPadding(padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom))
              ],
            );
          }
        },
      ),
    );
  }

  List<Widget> buildTitle(ComicPageLogic<T> logic){
    return [
      SliverAppBar(
        surfaceTintColor: logic.showAppbarTitle?null:Colors.transparent,
        shadowColor: Colors.transparent,
        title: AnimatedOpacity(
          opacity: logic.showAppbarTitle?1.0:0.0,
          duration: const Duration(milliseconds: 200),
          child: Text("$title${pages==null?"":"(${pages}P)"}"),
        ),
        pinned: true,
        actions: [
          Tooltip(
            message: "分享".tr,
            child: IconButton(
              icon: const Icon(Icons.share,),
              onPressed: () {
                Share.share(title!);
              },
            ),),
          Tooltip(
            message: "复制".tr,
            child: IconButton(
              icon: const Icon(Icons.copy,),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: title!));
              },
            ),),
        ],
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
          child: SizedBox(
            width: double.infinity,
            child: CustomSelectableText(
              text: "$title${pages==null?"":"(${pages}P)"}",
              style: const TextStyle(fontSize: 28),
              withAddToBlockKeywordButton: true,
            ),
          ),
        ),
      ),
    ];
  }

  Widget buildComicInfo(ComicPageLogic<T> logic, BuildContext context){
    if(UiMode.m1(context)) {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: MediaQuery.of(context).size.width/2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //封面
              buildCover(context, logic, 350, MediaQuery.of(context).size.width),

              const SizedBox(height: 20,),

              ...buildInfoCards(logic, context),
            ],
          ),
        ),
      );
    }
    else {
      return SliverToBoxAdapter(child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            buildCover(context, logic, 550, MediaQuery.of(context).size.width/2),
            SizedBox(
              width: MediaQuery.of(context).size.width/2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buildInfoCards(logic, context),
              ),
            ),
          ],
        ),
      ),);
    }
  }

  Widget buildCover(BuildContext context, ComicPageLogic logic, double height, double width){
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: CachedNetworkImage(
          width: width-32,
          height: height-32,
          imageUrl: cover,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      onTap: ()=>Get.to(()=>ShowImagePage(cover)),
    );
  }

  Widget buildInfoCard(String text, BuildContext context, {bool title=false}){
    final colorScheme = Theme.of(context).colorScheme;
    double size = 1;
    int values = 0;
    for(var v in tags!.values.toList()){
      values += v.length;
    }
    if(values < 20){
      size = size*1.5;
    }

    if(text == ""){
      text = "未知".tr;
    }

    return GestureDetector(
      onLongPressStart: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: Text("复制".tr),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (text)));
                  showMessage(context, "已复制".tr);
                },
              ),
              if(!title)
              PopupMenuItem(
                child: Text("添加到屏蔽词".tr),
                onTap: (){
                  appdata.blockingKeyword.add(text);
                  appdata.writeData();
                },
              ),
            ]
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: title?colorScheme.primaryContainer:colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(Radius.circular(12))
        ),
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: title?null:()=>tapOnTags(text),
          onSecondaryTapDown: (details){
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy
                ),
                items: [
                  PopupMenuItem(
                    child: Text("复制".tr),
                    onTap: (){
                      Clipboard.setData(ClipboardData(text: (text)));
                      showMessage(context, "已复制".tr);
                    },
                  ),
                  if(!title)
                  PopupMenuItem(
                    child: Text("添加到屏蔽词".tr),
                    onTap: (){
                      appdata.blockingKeyword.add(text);
                      appdata.writeData();
                    },
                  ),
                ]
            );
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(8*size, 5*size, 8*size, 5*size),
            child: enableTranslationToCN?(title?Text(text.translateTagsCategoryToCN):Text(text.translateTagsToCN)):Text(text),
          ),
        ),
      ),
    );
  }

  List<Widget> buildInfoCards(ComicPageLogic logic, BuildContext context){
    var res = <Widget>[];
    var res2 = <Widget>[];

    if(buildMoreInfo !=  null){
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        child: buildMoreInfo!,
      ));
    }

    if(actions != null) {
      res2.add(Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        child: actions,
      ));
    }

    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(child: downloadButton,),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: readButton,),
        ],
      ),
    ));

    for(var key in tags!.keys){
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
        child: Wrap(
          children: [
            buildInfoCard(key, context, title: true),
            for(var tag in tags![key]!)
              buildInfoCard(tag, context)
          ],
        ),
      ));
    }

    if(uploaderInfo != null) {
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        child: uploaderInfo,
      ));
    }

    return !UiMode.m1(context)?res+res2:res2+res;
  }

  List<Widget> buildEpisodeInfo(BuildContext context){
    if(eps == null) return [];

    return [
      const SliverToBoxAdapter(child: Divider(),),
      SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
        const SizedBox(width: 20,),
        Icon(Icons.library_books, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 20,),
        Text("章节".tr,style: const TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
      ],)),),
      const SliverPadding(padding: EdgeInsets.all(5)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: eps!.eps.length,
                  (context, i){
                return Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: Card(
                    elevation: 1,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    margin: EdgeInsets.zero,
                    child: Center(child: Text(eps!.eps[i]),),
                  ),
                  onTap: () => eps!.onTap(i),
                ),);
              }
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 4,
          ),
        ),
      )
    ];
  }

  List<Widget> buildIntroduction(BuildContext context){
    if(introduction == null)  return [];

    return [
      const SliverPadding(padding: EdgeInsets.all(5)),
      const SliverToBoxAdapter(child: Divider(),),
      SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
        const SizedBox(width: 20,),
        Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 20,),
        Text("简介".tr,style: const TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
      ],)),),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: CustomSelectableText(text: introduction!),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
    ];
  }

  List<Widget> buildThumbnails(BuildContext context){
    if(thumbnails == null || thumbnails!.thumbnails.isEmpty) return [];
    return [
      const SliverPadding(padding: EdgeInsets.all(5)),
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
                Icon(Icons.remove_red_eye,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                const Text(
                  "预览",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                )
              ],
            )),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                childCount: thumbnails!.thumbnails.length, (context, index) {
              if(index == thumbnails!.thumbnails.length-1){
                thumbnails!.get(update);
              }
              return Padding(
                padding: UiMode.m1(context)
                    ? const EdgeInsets.all(8)
                    : const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: thumbnails!.thumbnails[index],
                      fit: BoxFit.contain,
                      placeholder: (context, s) => ColoredBox(
                          color: Theme.of(context).colorScheme.surfaceVariant),
                      errorWidget: (context, s, d) => const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            }),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.75,
            )),
      ),
      if(thumbnails!.current < thumbnails!.maxPage)
        const SliverToBoxAdapter(
          child: ListLoadingIndicator(),
        ),
    ];
  }

  /// calculate title size
  Size boundingTextSize(String text, TextStyle style,
      {int maxLines = 2 ^ 31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style),
        maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  List<Widget> buildRecommendation(BuildContext context){
    var recommendation = recommendationBuilder(_logic.data!);
    if(recommendation == null) return[];
    return [
      const SliverToBoxAdapter(child: Divider(),),
      SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
        const SizedBox(width: 20,),
        Icon(Icons.recommend, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 20,),
        Text("相关推荐".tr,style: const TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
      ],)),),
      const SliverPadding(padding: EdgeInsets.all(5)),
      recommendation,
    ];
  }
}