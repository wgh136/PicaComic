import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/stars.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:share_plus/share_plus.dart';
import '../../eh_network/get_gallery_id.dart';
import '../reader/comic_reading_page.dart';
import '../show_image_page.dart';
import '../widgets/loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/widgets.dart';

class GalleryPageLogic extends GetxController{
  bool loading = true;
  Gallery? gallery;
  var controller = ScrollController();
  bool showAppbarTitle = false;
  NewHistory? history;
  bool noNetwork = false;

  void loadInfo(EhGalleryBrief brief) async{
    gallery = await ehNetwork.getGalleryInfo(brief);
    loading = false;
    update();
  }
  void retry(){
    loading = true;
    update();
  }
  void updateStars(double value){
    gallery!.stars = value/2;
    update;
  }
}

class EhGalleryPage extends StatelessWidget {
  const EhGalleryPage(this.brief,{this.downloaded = false,Key? key}) : super(key: key);
  final EhGalleryBrief brief;
  final bool downloaded;

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
          if(downloaded){
            logic.loading = false;
          }
          if(logic.loading){
            logic.loadInfo(brief);
            return showLoading(context);
          }else if(logic.gallery == null){
            if(downloadManager.downloadedGalleries.contains(getGalleryId(brief.link))){
              loadGalleryInfoFromFile(logic);
              return showLoading(context);
            }
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

                if(! logic.noNetwork)
                const SliverToBoxAdapter(
                  child: Divider(),
                ),

                if(! logic.noNetwork)
                buildComments(logic, context),
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

                if(! logic.noNetwork)
                const SizedBox(height: 20,),
                if(! logic.noNetwork)
                SizedBox(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("评分"),
                        SizedBox(
                          height: 30,
                          child: Row(
                            children: [
                              for(int i=0;i<s~/2;i++)
                                Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                              if(s%2==1)
                                Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                              for(int i=0;i<(5 - s~/2 - s%2);i++)
                                const Icon(Icons.star_border,size: 30,),
                              const SizedBox(width: 5,),
                              if(logic.gallery!.rating!=null)
                                Text(logic.gallery!.rating!)
                            ],
                          ),
                        ),
                      ]
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
                  if(! logic.noNetwork)
                  const Text("评分"),
                  if(! logic.noNetwork)
                  SizedBox(
                    height: 30,
                    child: Row(
                      children: [
                        for(int i=0;i<s~/2;i++)
                          Icon(Icons.star,size: 30,color: Theme.of(context).colorScheme.secondary,),
                        if(s%2==1)
                          Icon(Icons.star_half,size: 30,color: Theme.of(context).colorScheme.secondary,),
                        for(int i=0;i<(5 - s~/2 - s%2);i++)
                          const Icon(Icons.star_border,size: 30,),
                        const SizedBox(width: 5,),
                        if(logic.gallery!.rating!=null)
                          Text(logic.gallery!.rating!)
                      ],
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
      onTap: logic.noNetwork?null:()=>Get.to(()=>ShowImagePage(logic.gallery!.coverPath,eh: true,)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: logic.noNetwork?Image.file(
          downloadManager.getPicCover(getGalleryId(brief.link)),
          width: width-50,
          height: height,
          fit: BoxFit.contain,
        ):CachedNetworkImage(
          width: width-50,
          height: height,
          imageUrl: logic.gallery!.coverPath,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 0),
      child: Row(
        children: [
          Expanded(child: ActionChip(
            label: const Text("评分"),
            avatar: const Icon(Icons.star),
            onPressed: (){
              if(logic.noNetwork){
                showMessage(context, "无网络");
              }else{
                starRating(context, logic.gallery!.auth!);
              }
            },
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: ActionChip(
            label: const Text("收藏"),
            avatar: logic.gallery!.favorite?const Icon(Icons.bookmark):const Icon(Icons.bookmark_outline),
            onPressed: () {
              if(logic.noNetwork){
                showMessage(context, "无网络");
                return;
              }
              if(appdata.ehId==""){
                showMessage(context, "未登录");
                return;
              }
              if(logic.gallery!.favorite){
                ehNetwork.unfavorite(logic.gallery!.auth!["gid"]!, logic.gallery!.auth!["token"]!);
              }else{
                ehNetwork.favorite(logic.gallery!.auth!["gid"]!, logic.gallery!.auth!["token"]!);
              }
              logic.gallery!.favorite = !logic.gallery!.favorite;
              logic.update();
            }
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: ActionChip(
            label: const Text("评论"),
            avatar: const Icon(Icons.comment_outlined),
            onPressed: (){
              if(logic.noNetwork){
                showMessage(context, "无网络");
              }else{
                comment(context, logic.gallery!.link);
              }
            }
          ),),
        ],
      ),
    ));
    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 15, 20, 10),
      child: Row(
        children: [
          Expanded(child: FilledButton(
            onPressed: (){
              final id = getGalleryId(logic.gallery!.link);
              if(downloadManager.downloadedGalleries.contains(id)){
                showMessage(context, "已下载");
                return;
              }
              for(var i in downloadManager.downloading){
                if(i.id == id){
                  showMessage(context, "下载中");
                  return;
                }
              }
              downloadManager.addEhDownload(logic.gallery!);
              showMessage(context, "已加入下载队列");
            },
            child: (downloadManager.downloadedGalleries.contains(getGalleryId(logic.gallery!.link)))?const Text("已下载"):const Text("下载"),
          ),),
          SizedBox.fromSize(size: const Size(10,1),),
          Expanded(child: FilledButton(
            onPressed: (){
              if(logic.history!=null){
                if(logic.history!.ep!=0){
                  showDialog(context: context, builder: (dialogContext)=>AlertDialog(
                    title: const Text("继续阅读"),
                    content: Text("上次阅读到第${logic.history!.ep}章第${logic.history!.page}页, 是否继续阅读?"),
                    actions: [
                      TextButton(onPressed: (){
                        Get.back();
                        Get.to(()=>ComicReadingPage.ehentai(brief.link,logic.gallery!));
                      }, child: const Text("从头开始")),
                      TextButton(onPressed: (){
                        Get.back();
                        Get.to(()=>ComicReadingPage.ehentai(brief.link,logic.gallery!,initialPage: logic.history!.page));
                      }, child: const Text("继续阅读")),
                    ],
                  ));
                }else{
                  Get.to(()=>ComicReadingPage.ehentai(brief.link,logic.gallery!));
                }
              }else {
                Get.to(()=>ComicReadingPage.ehentai(brief.link,logic.gallery!));
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

  Widget buildComments(GalleryPageLogic logic, BuildContext context){
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: SizedBox(
          child: Column(
            children: [
              const SizedBox(
                width: 800,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 0, 5),
                  child: Text("评论",style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
                ),
              ),
              for(var comment in logic.gallery!.comments)
                SizedBox(
                  width: 800,
                  child: Card(
                    margin: const EdgeInsets.all(5),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${logic.gallery!.uploader==comment.name?"(上传者)":""}${comment.name}",style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                          const SizedBox(height: 2,),
                          Text(comment.content)
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),
      )
    );
  }

  void starRating(BuildContext context, Map<String, String> auth){
    if(appdata.ehId==""){
      showMessage(context, "未登录");
      return;
    }
    showDialog(context: context, builder: (dialogContext)=>GetBuilder<RatingLogic>(
      init: RatingLogic(),
      builder: (logic)=>SimpleDialog(
        title: const Text("评分"),
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 210,
                child: Column(
                  children: [
                    const SizedBox(height: 10,),
                    RatingWidget(
                      padding: 2,
                      onRatingUpdate: (value)=>logic.rating = value,
                      value: 0,
                      selectAble: true,
                      size: 40,
                    ),
                    const Spacer(),
                    if(!logic.running)
                      FilledButton(onPressed: (){
                        logic.running = true;
                        logic.update();
                        ehNetwork.rateGallery(auth,logic.rating.toInt()).then((b){
                          if(b){
                            Get.back();
                            showMessage(context, "评分成功");
                            Get.find<GalleryPageLogic>().updateStars(logic.rating);
                          }else{
                            logic.running = false;
                            logic.update();
                            showMessage(dialogContext, ehNetwork.status?ehNetwork.message:"网络错误");
                          }
                        });
                      }, child: const Text("提交"))
                    else
                      const CircularProgressIndicator()
                  ],
                ),
              ),
            ),
          )
        ],
      )
    ));
  }

  void comment(BuildContext context, String link){
    if(appdata.ehId==""){
      showMessage(context, "未登录");
      return;
    }
    showDialog(context: context, builder: (dialogContext)=>GetBuilder<CommentLogic>(
      init: CommentLogic(),
        builder: (logic)=>SimpleDialog(
          title: const Text("发布评论"),
          children: [
            SizedBox(
              width: 400,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
                    child: TextField(
                      maxLines: 5,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()
                      ),
                      controller: logic.controller,
                    ),
                  ),
                  if(!logic.sending)
                    FilledButton(onPressed: (){
                      logic.sending = true;
                      logic.update();
                      ehNetwork.comment(logic.controller.text,link).then((b){
                        if(b){
                          Get.back();
                          showMessage(context, "评论成功");
                          var pageLogic = Get.find<GalleryPageLogic>();
                          pageLogic.gallery!.comments.add(Comment(appdata.ehAccount, logic.controller.text, "now"));
                          pageLogic.update();
                        }else{
                          logic.sending = false;
                          logic.update();
                          showMessage(context, ehNetwork.status?ehNetwork.message:"网络错误");
                        }
                      });
                    }, child: const Text("提交"))
                  else
                    const CircularProgressIndicator()
                ],
              ),
            )
          ],
    )));
  }

  void loadGalleryInfoFromFile(GalleryPageLogic logic) async{
    logic.gallery = (await downloadManager.getGalleryFormId(getGalleryId(brief.link))).gallery;
    //避免加载完成后页面还没有渲染完成
    await Future.delayed(const Duration(milliseconds: 100));
    logic.noNetwork = true;
    logic.update();
  }
}

class RatingLogic extends GetxController{
  double rating = 0;
  bool running = false;
}

class CommentLogic extends GetxController{
  final controller = TextEditingController();
  bool sending = false;
}