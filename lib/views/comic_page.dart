import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/category_comic_page.dart';
import 'package:pica_comic/views/comic_reading_page.dart';
import 'package:pica_comic/views/comments_page.dart';
import 'package:pica_comic/views/show_image_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/base.dart';

class ComicPageLogic extends GetxController{
  bool isLoading = true;
  ComicItem? comicItem;
  bool underReview = false;
  bool noNetwork = false;
  var tags = <Widget>[];
  var categories = <Widget>[];
  var recommendation = <ComicItemBrief>[];
  var eps = <Widget>[
    const ListTile(
      leading: Icon(Icons.library_books),
      title: Text("章节"),
    ),
  ];
  var epsStr = <String>[""];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ComicPage extends StatelessWidget{
  final ComicItemBrief comic;
  final bool downloaded;
  const ComicPage(this.comic,{super.key, this.downloaded=false});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ComicPageLogic>(
        tag: comic.id,
        init: ComicPageLogic(),
          builder: (logic){
          if(downloaded){
            logic.isLoading = false;
          }
          if(logic.isLoading){
            network.getComicInfo(comic.id).then((c) {
              if(network.status){
                logic.underReview = true;
                logic.change();
                return;
              }
              if (c != null) {
                logic.comicItem = c;
                for (String s in c.tags) {
                  logic.tags.add(GestureDetector(
                    onTap: () {
                      Get.to(() => CategoryComicPage(s));
                    },
                    onLongPress: (){
                      Clipboard.setData(ClipboardData(text: (s)));
                      showMessage(context, "已复制");
                    },
                    onSecondaryTapUp: (details){
                      showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                          items: [
                            PopupMenuItem(
                              child: const Text("复制"),
                              onTap: (){
                                Clipboard.setData(ClipboardData(text: (s)));
                                showMessage(context, "已复制");
                              },
                            )
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(s),),
                    ),
                  ));
                }
                for (String s in c.categories) {
                  logic.categories.add(GestureDetector(
                    onTap: () {
                      Get.to(() => CategoryComicPage(s));
                    },
                    onLongPress: (){
                      Clipboard.setData(ClipboardData(text: (s)));
                      showMessage(context, "已复制");
                    },
                    onSecondaryTapUp: (details){
                      showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                          items: [
                            PopupMenuItem(
                              child: const Text("复制"),
                              onTap: (){
                                Clipboard.setData(ClipboardData(text: (s)));
                                showMessage(context, "已复制");
                              },
                            )
                          ]
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      elevation: 0,
                      color: Theme
                          .of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(s),),
                    ),
                  ));
                }
                bool flag1 = false;
                bool flag2 = false;
                network.getRecommendation(comic.id).then((r){
                  logic.recommendation = r;
                  flag1 = true;
                  if(flag1&&flag2){
                    logic.change();
                  }
                });
                network.getEps(comic.id).then((e) {
                  for (int i = 1; i < e.length; i++) {
                    logic.epsStr.add(e[i]);
                    logic.eps.add(ListTile(
                      title: Text(e[i]),
                      onTap: () {
                        Get.to(() =>
                            ComicReadingPage(comic.id, i, logic.epsStr, comic.title));
                      },
                    ));
                  }
                  flag2 = true;
                  if(flag1&&flag2){
                    logic.change();
                  }
                });
              } else {
                logic.change();
              }
            });
          return showLoading(context);
        }else if(logic.comicItem!=null){
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text("漫画详情"),
                pinned: true,
                actions: [
                  Tooltip(
                    message: "复制标题",
                    child: IconButton(
                      icon: const Icon(Icons.copy,),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: comic.title));
                        showMessage(context, "已复制标题");
                      },
                    ),)
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 0, 10, 15),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(comic.title, style: const TextStyle(fontSize: 22),),
                  ),
                ),
              ),
              if(MediaQuery.of(context).size.shortestSide<changePoint)
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width/2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if(downloaded)
                        Image.file(
                          downloadManager.getCover(comic.id),
                          height: 350,
                          width: MediaQuery.of(context).size.width,
                        )
                        else
                        GestureDetector(
                          child: CachedNetworkImage(
                            imageUrl: getImageUrl(comic.path),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                            height: 350,
                            width: MediaQuery.of(context).size.width,
                          ),
                          onTap: (){Get.to(()=>ShowImagePage(comic.path));},
                        ),
                        const SizedBox(height: 20,),
                        if(logic.comicItem!.author!="")
                        const SizedBox(
                          height: 20,
                          child: Text("      作者"),
                        ),
                        if(logic.comicItem!.author!="")
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                            child: GestureDetector(
                              child: Card(
                                elevation: 0,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                  child: Text(logic.comicItem!.author),
                                ),
                              ),
                              onTap: (){
                                if(logic.comicItem!.author!=""){
                                  Get.to(()=>CategoryComicPage(logic.comicItem!.author));
                                }
                              },
                              onLongPress: (){
                                Clipboard.setData(ClipboardData(text: (logic.comicItem!.author)));
                                showMessage(context, "已复制");
                              },
                              onSecondaryTapUp: (details){
                                showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                                    items: [
                                      PopupMenuItem(
                                        child: const Text("复制"),
                                        onTap: (){
                                          Clipboard.setData(ClipboardData(text: (logic.comicItem!.author)));
                                          showMessage(context, "已复制");
                                        },
                                      )
                                    ]
                                );
                              },
                            )
                        ),
                        if(logic.comicItem!.chineseTeam!="")
                        const SizedBox(
                          height: 20,
                          child: Text("      汉化组"),
                        ),
                        if(logic.comicItem!.chineseTeam!="")
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                            child: GestureDetector(
                              child: Card(
                                elevation: 0,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                  child: Text(logic.comicItem!.chineseTeam),
                                ),
                              ),
                              onTap: (){
                                if(logic.comicItem!.chineseTeam!=""){
                                  Get.to(()=>CategoryComicPage(logic.comicItem!.chineseTeam));
                                }
                              },
                              onLongPress: (){
                                Clipboard.setData(ClipboardData(text: (logic.comicItem!.chineseTeam)));
                                showMessage(context, "已复制");
                              },
                              onSecondaryTapUp: (details){
                                showMenu(
                                    context: context,
                                    position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                                    items: [
                                      PopupMenuItem(
                                          child: const Text("复制"),
                                          onTap: (){
                                            Clipboard.setData(ClipboardData(text: (logic.comicItem!.chineseTeam)));
                                            showMessage(context, "已复制");
                                          },
                                      )
                                    ]
                                );
                              },
                            )
                        ),
                        const SizedBox(
                          height: 20,
                          child: Text("      分类"),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                          child: Wrap(
                            children: logic.categories,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                          child: Text("      标签"),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                          child: Wrap(
                            children: logic.tags,
                          ),
                        ),
                        if(!downloaded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                          child: Card(
                            elevation: 0,
                            color: Theme.of(context).colorScheme.inversePrimary,
                            child: SizedBox(
                              height: 60,
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 0,
                                    child: Avatar(
                                    size: 50,
                                    avatarUrl: logic.comicItem!.creator.avatarUrl,
                                    frame: logic.comicItem!.creator.frameUrl,
                                      couldBeShown: true,
                                      name: logic.comicItem!.creator.name,
                                      slogan: logic.comicItem!.creator.slogan,
                                      level: logic.comicItem!.creator.level,
                                  ),),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              logic.comicItem!.creator.name,
                                            style: const TextStyle(fontSize: 15,fontWeight: FontWeight.w600),
                                          ),
                                          Text("${logic.comicItem!.time.substring(0,10)} ${logic.comicItem!.time.substring(11,19)}更新")
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if(!downloaded)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                          child: Row(
                            children: [
                              Expanded(child: ActionChip(
                                label: Text(logic.comicItem!.likes.toString()),
                                avatar: Icon((logic.comicItem!.isLiked)?Icons.favorite:Icons.favorite_border),
                                onPressed: (){
                                  if(logic.noNetwork){
                                    showMessage(context, "无网络");
                                    return;
                                  }
                                  network.likeOrUnlikeComic(comic.id);
                                  logic.comicItem!.isLiked = !logic.comicItem!.isLiked;
                                  logic.update();
                                },
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: ActionChip(
                                label: const Text("收藏"),
                                avatar: Icon((logic.comicItem!.isFavourite)?Icons.bookmark:Icons.bookmark_outline),
                                onPressed: (){
                                  if(logic.noNetwork){
                                    showMessage(context, "无网络");
                                    return;
                                  }
                                  network.favouriteOrUnfavoriteComic(comic.id);
                                  logic.comicItem!.isFavourite = !logic.comicItem!.isFavourite;
                                  logic.update();
                                },
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: ActionChip(
                                label: Text(logic.comicItem!.comments.toString()),
                                avatar: const Icon(Icons.comment_outlined),
                                onPressed: (){
                                  if(logic.noNetwork){
                                    showMessage(context, "无网络");
                                    return;
                                  }
                                  Get.to(()=>CommentsPage(comic.id));
                                },
                              ),),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Row(
                            children: [
                              Expanded(child: FilledButton(
                                onPressed: (){
                                  downloadComic(logic.comicItem!, context);
                                },
                                child: (downloadManager.downloaded.contains(comic.id))?const Text("已下载"):const Text("下载"),
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: FilledButton(
                                onPressed: (){
                                  Get.to(()=>ComicReadingPage(comic.id, 1, logic.epsStr,comic.title));
                                },
                                child: const Text("阅读"),
                              ),),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              //以下为大屏设备的显示
              if(MediaQuery.of(context).size.shortestSide>=changePoint)
                SliverToBoxAdapter(child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      if(downloaded)
                        Image.file(
                          downloadManager.getCover(comic.id),
                          height: 550,
                          width: MediaQuery.of(context).size.width/2,
                        )
                      else
                      GestureDetector(
                        child: CachedNetworkImage(
                          imageUrl: getImageUrl(comic.path),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          height: 550,
                          width: MediaQuery.of(context).size.width/2,
                        ),
                        onTap: (){
                          Get.to(ShowImagePage(comic.path));
                        },
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width/2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(logic.comicItem!.author!="")
                            const SizedBox(
                              height: 30,
                              child: Text("      作者"),
                            ),
                            if(logic.comicItem!.author!="")
                            Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                                child: GestureDetector(
                                  child: Card(
                                    elevation: 0,
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                      child: Text(logic.comicItem!.author),
                                    ),
                                  ),
                                  onTap: (){
                                    if(logic.comicItem!.author!=""){
                                      Get.to(()=>CategoryComicPage(logic.comicItem!.author));
                                    }
                                  },
                                  onLongPress: (){
                                    Clipboard.setData(ClipboardData(text: (logic.comicItem!.author)));
                                    showMessage(context, "已复制");
                                  },
                                  onSecondaryTapUp: (details){
                                    showMenu(
                                        context: context,
                                        position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                                        items: [
                                          PopupMenuItem(
                                            child: const Text("复制"),
                                            onTap: (){
                                              Clipboard.setData(ClipboardData(text: (logic.comicItem!.author)));
                                              showMessage(context, "已复制");
                                            },
                                          )
                                        ]
                                    );
                                  },
                                )
                            ),
                            if(logic.comicItem!.chineseTeam!="")
                            const SizedBox(
                              height: 30,
                              child: Text("      汉化组"),
                            ),
                            if(logic.comicItem!.chineseTeam!="")
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                              child: GestureDetector(
                                child: Card(
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                                    child: Text(logic.comicItem!.chineseTeam),
                                  ),
                                ),
                                onTap: (){
                                  if(logic.comicItem!.chineseTeam!=""){
                                    Get.to(()=>CategoryComicPage(logic.comicItem!.chineseTeam));
                                  }
                                },
                                onLongPress: (){
                                  Clipboard.setData(ClipboardData(text: (logic.comicItem!.chineseTeam)));
                                  showMessage(context, "已复制");
                                },
                                onSecondaryTapUp: (details){
                                  showMenu(
                                      context: context,
                                      position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                                      items: [
                                        PopupMenuItem(
                                          child: const Text("复制"),
                                          onTap: (){
                                            Clipboard.setData(ClipboardData(text: (logic.comicItem!.chineseTeam)));
                                            showMessage(context, "已复制");
                                          },
                                        )
                                      ]
                                  );
                                },
                              )
                            ),
                            const SizedBox(
                              height: 30,
                              child: Text("      分类"),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                              child: Wrap(
                                children: logic.categories,
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                              child: Text("      标签"),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                              child: Wrap(
                                children: logic.tags,
                              ),
                            ),
                            if(!downloaded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                              child: Card(
                                elevation: 0,
                                color: Theme.of(context).colorScheme.inversePrimary,
                                child: SizedBox(
                                  height: 60,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 0,
                                        child: Avatar(
                                          size: 50,
                                          avatarUrl: logic.comicItem!.creator.avatarUrl,
                                          frame: logic.comicItem!.creator.frameUrl,
                                          couldBeShown: true,
                                          name: logic.comicItem!.creator.name,
                                          slogan: logic.comicItem!.creator.slogan,
                                          level: logic.comicItem!.creator.level,
                                        ),),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                logic.comicItem!.creator.name,
                                                style: const TextStyle(fontSize: 15,fontWeight: FontWeight.w600),
                                              ),
                                              Text("${logic.comicItem!.time.substring(0,10)} ${logic.comicItem!.time.substring(11,19)}更新")
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if(!downloaded)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                              child: Row(
                                children: [
                                  Expanded(child: ActionChip(
                                    label: Text(logic.comicItem!.likes.toString()),
                                    avatar: Icon((logic.comicItem!.isLiked)?Icons.favorite:Icons.favorite_border),
                                    onPressed: (){
                                      if(logic.noNetwork){
                                        showMessage(context, "无网络");
                                        return;
                                      }
                                      network.likeOrUnlikeComic(comic.id);
                                      logic.comicItem!.isLiked = !logic.comicItem!.isLiked;
                                      logic.update();
                                    },
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: ActionChip(
                                    label: const Text("收藏"),
                                    avatar: Icon((logic.comicItem!.isFavourite)?Icons.bookmark:Icons.bookmark_outline),
                                    onPressed: (){
                                      if(logic.noNetwork){
                                        showMessage(context, "无网络");
                                        return;
                                      }
                                      network.favouriteOrUnfavoriteComic(comic.id);
                                      logic.comicItem!.isFavourite = !logic.comicItem!.isFavourite;
                                      logic.update();
                                    },
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: ActionChip(
                                    label: Text(logic.comicItem!.comments.toString()),
                                    avatar: const Icon(Icons.comment_outlined),
                                    onPressed: (){
                                      if(logic.noNetwork){
                                        showMessage(context, "无网络");
                                        return;
                                      }
                                      Get.to(()=>CommentsPage(comic.id));
                                    },
                                  ),),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                              child: Row(
                                children: [
                                  Expanded(child: FilledButton(
                                    onPressed: (){
                                      downloadComic(logic.comicItem!, context);
                                    },
                                    child: (downloadManager.downloaded.contains(comic.id))?const Text("已下载"):const Text("下载"),
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: FilledButton(
                                    onPressed: (){
                                      Get.to(()=>ComicReadingPage(comic.id, 1, logic.epsStr,comic.title));
                                    },
                                    child: const Text("阅读"),
                                  ),),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),),
              const SliverPadding(padding: EdgeInsets.all(5)),

              //章节显示
              const SliverToBoxAdapter(child: Divider(),),
              SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
                const SizedBox(width: 20,),
                Icon(Icons.library_books, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 20,),
                const Text("章节",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
              ],)),),
              const SliverPadding(padding: EdgeInsets.all(5)),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: logic.epsStr.length-1,
                        (context, i){
                      return Padding(padding: const EdgeInsets.all(1),child: GestureDetector(
                        child: Card(
                          elevation: 1,
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          child: Center(child: Text(logic.epsStr[i+1]),),
                        ),
                        onTap: () {
                          Get.to(() =>
                              ComicReadingPage(comic.id, i+1, logic.epsStr, comic.title));
                        },
                      ),);
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  childAspectRatio: 4,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.all(5)),
              const SliverToBoxAdapter(child: Divider(),),
              SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
                const SizedBox(width: 20,),
                Icon(Icons.insert_drive_file, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 20,),
                const Text("简介",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
              ],)),),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
                  child: Text(logic.comicItem!.description),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.all(5)),
              if(!downloaded)
              const SliverToBoxAdapter(child: Divider(),),
              if(!downloaded)
              SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
                const SizedBox(width: 20,),
                Icon(Icons.recommend, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 20,),
                const Text("相关推荐",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
              ],)),),
              if(!downloaded)
              const SliverPadding(padding: EdgeInsets.all(5)),
              if(!downloaded)
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: logic.recommendation.length,
                        (context, i){
                      return ComicTile(logic.recommendation[i]);
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 3.5,
                ),
              ),
              if(!downloaded)
              const SliverPadding(padding: EdgeInsets.all(10)),
              SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
            ],
          );
        }else{
          if(downloadManager.downloaded.contains(comic.id)){
            //无网络时查询是否已经下载
            downloadManager.getComicFromId(comic.id).then((downloadComic){
              logic.isLoading = false;
              logic.comicItem = downloadComic.comicItem;
              for (String s in logic.comicItem!.tags) {
                logic.tags.add(GestureDetector(
                  onTap: () {
                    Get.to(() => CategoryComicPage(s));
                  },
                  onLongPress: (){
                    Clipboard.setData(ClipboardData(text: (s)));
                    showMessage(context, "已复制");
                  },
                  onSecondaryTapUp: (details){
                    showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                        items: [
                          PopupMenuItem(
                            child: const Text("复制"),
                            onTap: (){
                              Clipboard.setData(ClipboardData(text: (s)));
                              showMessage(context, "已复制");
                            },
                          )
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(s),),
                  ),
                ));
              }
              for (String s in logic.comicItem!.categories) {
                logic.categories.add(GestureDetector(
                  onTap: () {
                    Get.to(() => CategoryComicPage(s));
                  },
                  onLongPress: (){
                    Clipboard.setData(ClipboardData(text: (s)));
                    showMessage(context, "已复制");
                  },
                  onSecondaryTapUp: (details){
                    showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
                        items: [
                          PopupMenuItem(
                            child: const Text("复制"),
                            onTap: (){
                              Clipboard.setData(ClipboardData(text: (s)));
                              showMessage(context, "已复制");
                            },
                          )
                        ]
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                    elevation: 0,
                    color: Theme
                        .of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(s),),
                  ),
                ));
              }

              for (int i = 1; i < downloadComic.chapters.length; i++) {
                logic.epsStr.add(downloadComic.chapters[i]);
                logic.eps.add(ListTile(
                  title: Text(downloadComic.chapters[i]),
                  onTap: () {
                    Get.to(() =>
                        ComicReadingPage(comic.id, i, logic.epsStr, comic.title));
                  },
                ));
              }

              logic.comicItem!.likes = 0;
              logic.comicItem!.comments = 0;
              logic.noNetwork = true;
              logic.update();
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return showNetworkError(context, () {
            logic.change();
          });
        }
      }),
    );
  }
}

class ComicInfoTile extends StatelessWidget {
  final String title;
  final String content;
  const ComicInfoTile(this.title,this.content,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,style: const TextStyle(fontWeight: FontWeight.w600),),
          Text(content)
        ],
      ),
    );
  }
}

void downloadComic(ComicItem comic, BuildContext context){
  if(GetPlatform.isWeb){
    showMessage(context, "Web端不支持下载");
    return;
  }
  if(downloadManager.downloaded.contains(comic.id)){
    showMessage(context, "已下载");
    return;
  }
  for(var i in downloadManager.downloading){
    if(i.id == comic.id){
      showMessage(context, "下载中");
      return;
    }
  }
  downloadManager.addDownload(comic);
  showMessage(context, "已加入下载队列");
}