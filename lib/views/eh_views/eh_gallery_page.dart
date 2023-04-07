import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:share_plus/share_plus.dart';
import '../comic_reading_page.dart';
import '../show_image_page.dart';
import '../widgets/loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/widgets.dart';

/*
TODO:
  1. 评论
  2. 在此页面加载时获取星星, 发布者, 类型, 发布时间
  3. 优化ui
 */

class GalleryPageLogic extends GetxController{
  bool loading = true;
  Gallery? gallery;
  var controller = ScrollController();
  bool showAppbarTitle = false;
  NewHistory? history;

  void loadInfo(EhGalleryBrief brief) async{
    gallery = await ehNetwork.getGalleryInfo(brief);
    loading = false;
    update();
  }
  void retry(){
    loading = true;
    update();
  }
}

class EhGalleryPage extends StatelessWidget {
  const EhGalleryPage(this.brief,{Key? key}) : super(key: key);
  final EhGalleryBrief brief;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<GalleryPageLogic>(
        init: GalleryPageLogic(),
        initState: (logic){
          //添加历史记录
          Future.delayed(const Duration(milliseconds: 300),(){
            try{
              logic.controller!.history = NewHistory(
                  HistoryType.ehentai,
                  DateTime.now(),
                  brief.title,
                  brief.uploader,
                  brief.coverPath,
                  0,
                  0,
                  brief.link
              );
              appdata.history.addHistory(logic.controller!.history!);
            }
            catch(e){
              //Get会在初始化logic前调用此函数, 延迟300ms可能仍然没有初始化完成
            }
          });
        },
        builder: (logic){
          if(logic.loading){
            logic.loadInfo(brief);
            return showLoading(context);
          }else if(logic.gallery == null){
            return showNetworkError(context, logic.retry, eh: true);
          }else{
            logic.controller.addListener(() {
              //检测当前滚动位置, 决定是否显示Appbar的标题
              bool temp = logic.showAppbarTitle;
              logic.showAppbarTitle = logic.controller.position.pixels>
                  boundingTextSize(
                      logic.gallery!.title,
                      const TextStyle(fontSize: 22),
                      maxWidth: MediaQuery.of(context).size.width
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
                    child: Text(logic.gallery!.title),
                  ),
                  pinned: true,
                  actions: [
                    Tooltip(
                      message: "分享",
                      child: IconButton(
                        icon: const Icon(Icons.share,),
                        onPressed: () {
                          Share.share(logic.gallery!.title);
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
                        text: logic.gallery!.title,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),

                buildGalleryInfo(context,logic),

                if(logic.gallery!.commentByUploader!=null)
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(5),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("来自上传者",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                          const SizedBox(height: 2,),
                          Text(logic.gallery!.commentByUploader!)
                        ],
                      ),
                    ),
                  ),
                )
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildGalleryInfo(BuildContext context, GalleryPageLogic logic){
    var s = logic.gallery!.stars ~/ 0.5;
    if(UiMode.m1(context)){
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                //封面
                buildCover(context, 350, MediaQuery.of(context).size.width, logic),

                const SizedBox(height: 20,),

                SizedBox(
                  height: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for(int i=0;i<s~/2;i++)
                        Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                      if(s%2==1)
                        Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                      for(int i=0;i<(5 - s~/2 - s%2);i++)
                        const Icon(Icons.star_border,size: 30,)
                    ],
                  ),
                ),

                ...buildInfoCards(logic, context),
              ],
            ),
          ),
        ),
      );
    }else{
      return SliverToBoxAdapter(child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            //封面
            SizedBox(
              child: Column(
                children: [
                  buildCover(context, 550, MediaQuery.of(context).size.width/2,logic),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width/2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("评分"),
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: (){},
                    child: SizedBox(
                      height: 30,
                      width: 150,
                      child: Row(
                        children: [
                          for(int i=0;i<s~/2;i++)
                            Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                          if(s%2==1)
                            Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                          for(int i=0;i<(5 - s~/2 - s%2);i++)
                            const Icon(Icons.star_border,size: 30,)
                        ],
                      ),
                    ),
                  ),
                  ...buildInfoCards(logic, context),
                ]
              ),
            ),
          ],
        ),
      ),);
    }
  }

  Widget buildCover(BuildContext context, double height, double width, GalleryPageLogic logic){
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: CachedNetworkImage(
          width: width-50,
          height: height,
          imageUrl: logic.gallery!.coverPath,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      onTap: ()=>Get.to(()=>ShowImagePage(logic.gallery!.coverPath,eh: true,)),
    );
  }

  List<Widget> buildInfoCards(GalleryPageLogic logic, BuildContext context){
    var res = <Widget>[];
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("type"),
    ));
    res.add(buildInfoCard(logic.gallery!.type, context));
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("time"),
    ));
    res.add(buildInfoCard(logic.gallery!.time, context,allowSearch: false));
    for(var key in logic.gallery!.tags.keys){
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Text(key),
      ));
      res.add(Wrap(
        children: [
          for(var s in logic.gallery!.tags[key]!)
            buildInfoCard(s, context),
        ],
      ));
    }
    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 10),
      child: Row(
        children: [
          Expanded(child: FilledButton(
            onPressed: (){
              Get.to(()=>ComicReadingPage(brief.link,1,const [],logic.gallery!.title,ehUrls: logic.gallery!.urls,));
              if(logic.history!=null){
                if(logic.history!.ep!=0){
                  showDialog(context: context, builder: (dialogContext)=>AlertDialog(
                    title: const Text("继续阅读"),
                    content: Text("上次阅读到第${logic.history!.ep}章第${logic.history!.page}页, 是否继续阅读?"),
                    actions: [
                      TextButton(onPressed: (){
                        Get.back();
                        Get.to(()=>ComicReadingPage(brief.link, 1, const [],logic.gallery!.title,ehUrls: logic.gallery!.urls));
                      }, child: const Text("从头开始")),
                      TextButton(onPressed: (){
                        Get.back();
                        Get.to(()=>ComicReadingPage(brief.link, 1, const [],logic.gallery!.title,initialPage: logic.history!.page,ehUrls: logic.gallery!.urls));
                      }, child: const Text("继续阅读")),
                    ],
                  ));
                }else{
                  Get.to(()=>ComicReadingPage(brief.link, 1, const [],logic.gallery!.title,ehUrls: logic.gallery!.urls));
                }
              }else {
                Get.to(()=>ComicReadingPage(brief.link, 1, const [],logic.gallery!.title,ehUrls: logic.gallery!.urls));
              }
            },
            child: const Text("阅读"),
          ),),
        ],
      ),
    ));
    return res;
  }

  Widget buildInfoCard(String title, BuildContext context, {bool allowSearch=true}){
    return GestureDetector(
      onLongPressStart: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: const Text("复制"),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制");
                },
              ),
            ]
        );
      },
      onSecondaryTapUp: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: const Text("复制"),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制");
                },
              ),
            ]
        );
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        elevation: 0,
        color: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: allowSearch?()=>Get.to(()=>EhSearchPage(title)):(){},
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(title),
          ),
        ),
      ),
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
}
