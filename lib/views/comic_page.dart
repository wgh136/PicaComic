import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/category_comic_page.dart';
import 'package:pica_comic/views/comic_reading_page.dart';
import 'package:pica_comic/views/comments_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

import '../base.dart';

class ComicPageLogic extends GetxController{
  bool isLoading = true;
  ComicItem? comicItem;
  bool underReview = false;
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
  const ComicPage(this.comic, {super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ComicPageLogic>(
        tag: comic.id,
        init: ComicPageLogic(),
          builder: (comicPageLogic){
        if(comicPageLogic.isLoading){
            network.getComicInfo(comic.id).then((c) {
              if(network.status){
                comicPageLogic.underReview = true;
                comicPageLogic.change();
                return;
              }
              if (c != null) {
                comicPageLogic.comicItem = c;
                for (String s in c.tags) {
                  comicPageLogic.tags.add(GestureDetector(
                    onTap: () {
                      Get.to(() => CategoryComicPage(s));
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
                  comicPageLogic.categories.add(GestureDetector(
                    onTap: () {
                      Get.to(() => CategoryComicPage(s));
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
                bool flag1 = false;
                bool flag2 = false;
                network.getRecommendation(comic.id).then((r){
                  comicPageLogic.recommendation = r;
                  flag1 = true;
                  if(flag1&&flag2){
                    comicPageLogic.change();
                  }
                });
                network.getEps(comic.id).then((e) {
                  for (int i = 1; i < e.length; i++) {
                    comicPageLogic.epsStr.add(e[i]);
                    comicPageLogic.eps.add(ListTile(
                      title: Text(e[i]),
                      onTap: () {
                        Get.to(() =>
                            ComicReadingPage(comic.id, i, comicPageLogic.epsStr, comic.title));
                      },
                    ));
                  }
                  flag2 = true;
                  if(flag1&&flag2){
                    comicPageLogic.change();
                  }
                });
              } else {
                comicPageLogic.change();
              }
            });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(comicPageLogic.comicItem!=null){
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: Text(comic.title,maxLines: 1,overflow: TextOverflow.ellipsis,),
                actions: [
                  Tooltip(
                    message: "更多",
                    child: IconButton(
                      icon: const Icon(Icons.info_outline),
                      onPressed: () {
                        showDialog<String>(
                          context: context,
                          builder: (BuildContext context) => SimpleDialog(
                            children: [Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SelectionArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    ListTile(
                                      title: const Text("标题"),
                                      subtitle: Text(comic.title),
                                    ),
                                    ListTile(
                                      title: const Text("作者"),
                                      subtitle: Text(comic.author),
                                    ),
                                    ListTile(
                                      title: const Text("上传者"),
                                      subtitle: Text(comicPageLogic.comicItem!.creator.name),
                                    ),
                                    ListTile(
                                      title: const Text("汉化组"),
                                      subtitle: Text(comicPageLogic.comicItem!.chineseTeam),
                                    ),
                                    ListTile(
                                      title: const Text("分类"),
                                      subtitle: Text(comicPageLogic.comicItem!.categories.toString().substring(1,comicPageLogic.comicItem!.categories.toString().length-1)),
                                    ),
                                    ListTile(
                                      title: const Text("Tags"),
                                      subtitle: Text(comicPageLogic.comicItem!.tags.toString().substring(1,comicPageLogic.comicItem!.tags.toString().length-1)),
                                    ),
                                    SizedBox(
                                      height: 50,
                                      child: Row(
                                        children: const[
                                          Padding(padding: EdgeInsets.only(left: 18)),
                                          Icon(Icons.info),
                                          Padding(padding: EdgeInsets.only(left: 5)),
                                          Text("此界面文字可复制")
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ),
                        ]
                          ),
                        );
                      },
                    ),)
                ],
              ),
              if(MediaQuery.of(context).size.shortestSide<changePoint)
                SliverToBoxAdapter(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width/2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          imageUrl: getImageUrl(comic.path),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          height: 450,
                          width: MediaQuery.of(context).size.width,
                        ),
                        const SizedBox(height: 20,),
                        if(comicPageLogic.comicItem!.author!="")
                        const SizedBox(
                          height: 30,
                          child: Text("      作者"),
                        ),
                        if(comicPageLogic.comicItem!.author!="")
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                            child: GestureDetector(
                              child: Card(
                                elevation: 0,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(comicPageLogic.comicItem!.author),
                              ),
                              onTap: (){
                                if(comicPageLogic.comicItem!.author!=""){
                                  Get.to(()=>CategoryComicPage(comicPageLogic.comicItem!.author));
                                }
                              },
                            )
                        ),
                        if(comicPageLogic.comicItem!.chineseTeam!="")
                        const SizedBox(
                          height: 30,
                          child: Text("      汉化组"),
                        ),
                        if(comicPageLogic.comicItem!.chineseTeam!="")
                        Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                            child: GestureDetector(
                              child: Card(
                                elevation: 0,
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Text(comicPageLogic.comicItem!.chineseTeam),
                              ),
                              onTap: (){
                                if(comicPageLogic.comicItem!.chineseTeam!=""){
                                  Get.to(()=>CategoryComicPage(comicPageLogic.comicItem!.chineseTeam));
                                }
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
                            children: comicPageLogic.categories,
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                          child: Text("      标签"),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                          child: Wrap(
                            children: comicPageLogic.tags,
                          ),
                        ),
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
                                    avatarUrl: comicPageLogic.comicItem!.creator.avatarUrl,
                                    frame: comicPageLogic.comicItem!.creator.frameUrl,
                                      couldBeShown: true,
                                      name: comicPageLogic.comicItem!.creator.name,
                                      slogan: comicPageLogic.comicItem!.creator.slogan,
                                      level: comicPageLogic.comicItem!.creator.level,
                                  ),),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              comicPageLogic.comicItem!.creator.name,
                                            style: const TextStyle(fontSize: 15,fontWeight: FontWeight.w600),
                                          ),
                                          Text("${comicPageLogic.comicItem!.time.substring(0,10)} ${comicPageLogic.comicItem!.time.substring(11,19)}更新")
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                          child: Row(
                            children: [
                              Expanded(child: ActionChip(
                                label: Text(comicPageLogic.comicItem!.likes.toString()),
                                avatar: Icon((comicPageLogic.comicItem!.isLiked)?Icons.favorite:Icons.favorite_border),
                                onPressed: (){
                                  network.likeOrUnlikeComic(comic.id);
                                  comicPageLogic.comicItem!.isLiked = !comicPageLogic.comicItem!.isLiked;
                                  comicPageLogic.update();
                                },
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: ActionChip(
                                label: const Text("收藏"),
                                avatar: Icon((comicPageLogic.comicItem!.isFavourite)?Icons.bookmark:Icons.bookmark_outline),
                                onPressed: (){
                                  network.favouriteOrUnfavoriteComic(comic.id);
                                  comicPageLogic.comicItem!.isFavourite = !comicPageLogic.comicItem!.isFavourite;
                                  comicPageLogic.update();
                                },
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: ActionChip(
                                label: Text(comicPageLogic.comicItem!.comments.toString()),
                                avatar: const Icon(Icons.comment_outlined),
                                onPressed: (){
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
                                  //Todo: 下载功能
                                  showMessage(context, "下载功能还没做");
                                },
                                child: const Text("下载"),
                              ),),
                              SizedBox.fromSize(size: const Size(10,1),),
                              Expanded(child: FilledButton(
                                onPressed: (){
                                  Get.to(()=>ComicReadingPage(comic.id, 1, comicPageLogic.epsStr,comic.title));
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
                      CachedNetworkImage(
                        imageUrl: getImageUrl(comic.path),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        height: 550,
                        width: MediaQuery.of(context).size.width/2,
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width/2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if(comicPageLogic.comicItem!.author!="")
                            const SizedBox(
                              height: 30,
                              child: Text("      作者"),
                            ),
                            if(comicPageLogic.comicItem!.author!="")
                            Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                                child: GestureDetector(
                                  child: Card(
                                    elevation: 0,
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Text(comicPageLogic.comicItem!.author),
                                  ),
                                  onTap: (){
                                    if(comicPageLogic.comicItem!.author!=""){
                                      Get.to(()=>CategoryComicPage(comicPageLogic.comicItem!.author));
                                    }
                                  },
                                )
                            ),
                            if(comicPageLogic.comicItem!.chineseTeam!="")
                            const SizedBox(
                              height: 30,
                              child: Text("      汉化组"),
                            ),
                            if(comicPageLogic.comicItem!.chineseTeam!="")
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                              child: GestureDetector(
                                child: Card(
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(comicPageLogic.comicItem!.chineseTeam),
                                ),
                                onTap: (){
                                  if(comicPageLogic.comicItem!.chineseTeam!=""){
                                    Get.to(()=>CategoryComicPage(comicPageLogic.comicItem!.chineseTeam));
                                  }
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
                                children: comicPageLogic.categories,
                              ),
                            ),
                            const SizedBox(
                              height: 30,
                              child: Text("      标签"),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 10, 10),
                              child: Wrap(
                                children: comicPageLogic.tags,
                              ),
                            ),
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
                                          avatarUrl: comicPageLogic.comicItem!.creator.avatarUrl,
                                          frame: comicPageLogic.comicItem!.creator.frameUrl,
                                          couldBeShown: true,
                                          name: comicPageLogic.comicItem!.creator.name,
                                          slogan: comicPageLogic.comicItem!.creator.slogan,
                                          level: comicPageLogic.comicItem!.creator.level,
                                        ),),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                comicPageLogic.comicItem!.creator.name,
                                                style: const TextStyle(fontSize: 15,fontWeight: FontWeight.w600),
                                              ),
                                              Text("${comicPageLogic.comicItem!.time.substring(0,10)} ${comicPageLogic.comicItem!.time.substring(11,19)}更新")
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                              child: Row(
                                children: [
                                  Expanded(child: ActionChip(
                                    label: Text(comicPageLogic.comicItem!.likes.toString()),
                                    avatar: Icon((comicPageLogic.comicItem!.isLiked)?Icons.favorite:Icons.favorite_border),
                                    onPressed: (){
                                      network.likeOrUnlikeComic(comic.id);
                                      comicPageLogic.comicItem!.isLiked = !comicPageLogic.comicItem!.isLiked;
                                      comicPageLogic.update();
                                    },
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: ActionChip(
                                    label: const Text("收藏"),
                                    avatar: Icon((comicPageLogic.comicItem!.isFavourite)?Icons.bookmark:Icons.bookmark_outline),
                                    onPressed: (){
                                      network.favouriteOrUnfavoriteComic(comic.id);
                                      comicPageLogic.comicItem!.isFavourite = !comicPageLogic.comicItem!.isFavourite;
                                      comicPageLogic.update();
                                    },
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: ActionChip(
                                    label: Text(comicPageLogic.comicItem!.comments.toString()),
                                    avatar: const Icon(Icons.comment_outlined),
                                    onPressed: (){
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
                                      //Todo: 下载功能
                                      showMessage(context, "下载功能还没做");
                                    },
                                    child: const Text("下载"),
                                  ),),
                                  SizedBox.fromSize(size: const Size(10,1),),
                                  Expanded(child: FilledButton(
                                    onPressed: (){
                                      Get.to(()=>ComicReadingPage(comic.id, 1, comicPageLogic.epsStr,comic.title));
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
              SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: const [
                SizedBox(width: 20,),
                Icon(Icons.library_books),
                SizedBox(width: 20,),
                Text("章节",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
              ],)),),
              const SliverPadding(padding: EdgeInsets.all(5)),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: comicPageLogic.epsStr.length-1,
                        (context, i){
                      return Padding(padding: const EdgeInsets.all(1),child: GestureDetector(
                        child: Card(
                          elevation: 1,
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          child: Center(child: Text(comicPageLogic.epsStr[i+1]),),
                        ),
                        onTap: () {
                          Get.to(() =>
                              ComicReadingPage(comic.id, i+1, comicPageLogic.epsStr, comic.title));
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
              SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: const [
                SizedBox(width: 20,),
                Icon(Icons.recommend),
                SizedBox(width: 20,),
                Text("相关推荐",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
              ],)),),
              const SliverPadding(padding: EdgeInsets.all(5)),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: comicPageLogic.recommendation.length,
                        (context, i){
                      return ComicTile(comicPageLogic.recommendation[i]);
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 3.5,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.all(10)),
            ],
          );
        }else{
          return Stack(
            children: [
              Positioned(top: 0,
                left: 0,child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),child: Tooltip(
                message: "返回",
                child: IconButton(
                  iconSize: 25,
                  icon: const Icon(Icons.arrow_back_outlined),
                  onPressed: (){Get.back();},
                ),
              ),),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height/2-80,
                left: 0,
                right: 0,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.error_outline,size:60,),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height/2-10,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(comicPageLogic.underReview?"漫画审核中":"网络错误"),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height/2+30,
                child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: FilledButton(
                        onPressed: (){
                          comicPageLogic.change();
                        },
                        child: const Text("重试"),
                      ),
                    )
                ),
              ),
            ],
          );
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

