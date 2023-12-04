import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/pic_views/comments_page.dart';
import 'package:pica_comic/views/show_image_page.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';

class GamePageLogic extends StateController{
  bool isLoading = true;
  GameInfo? gameInfo;

  var controller = ScrollController();
  void change(){
    isLoading = !isLoading;
    update();
  }
}

void gameDownload(BuildContext context, String url){
  showDialog(context: context, builder: (dialogContext){
    return AlertDialog(
      title: Text("下载游戏".tl),
      content: Text("将前往哔咔游戏下载页面, 是否继续".tl),
      actions: [
        TextButton(onPressed: () => App.globalBack(), child: Text("取消".tl)),
        TextButton(onPressed: (){
          App.globalBack();
          launchUrlString(url,mode: LaunchMode.externalApplication);
        }, child: Text("继续".tl))
      ],
    );
  });
}

class GamePage extends StatelessWidget {
  const GamePage(this.id,{Key? key}) : super(key: key);
  final String id;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<GamePageLogic>(
        init: GamePageLogic(),
        builder: (logic){
          if(logic.isLoading){
            network.getGameInfo(id).then((gi){
              if(gi.success) {
                logic.gameInfo = gi.data;
              }
              logic.change();
            });
            return showLoading(context,withScaffold: true);
          }else if(logic.gameInfo != null){
            return Scaffold(
              appBar: AppBar(title: Text(logic.gameInfo!.name,maxLines: 1,overflow: TextOverflow.ellipsis,),),
              body: CustomScrollView(
                slivers: [
                  //SliverAppBar.large(title: Text(logic.gameInfo.name,maxLines: 1,overflow: TextOverflow.ellipsis,),),
                  if(MediaQuery.of(context).size.shortestSide<changePoint)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          //crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              child: Image.network(
                                logic.gameInfo!.icon,
                                fit: BoxFit.contain,
                                width: MediaQuery.of(context).size.width-10,
                                height: 300,
                              ),
                              onTap: (){
                                App.globalTo(()=>ShowImagePage(logic.gameInfo!.icon));
                              },
                            ),
                            const SizedBox(height: 10,),
                            SizedBox(
                              height: 60,
                              child: Row(
                                children: [
                                  const Spacer(),
                                  SizedBox(
                                    child: ActionChip(
                                      avatar: const Icon(Icons.apartment_outlined),
                                      label: Text(logic.gameInfo!.publisher),
                                      onPressed: (){},
                                    ),
                                  ),
                                  const SizedBox(width: 5,),
                                  ActionChip(
                                    avatar: logic.gameInfo!.isLiked?const Icon(Icons.favorite):const Icon(Icons.favorite_border),
                                    label: Text(logic.gameInfo!.likes.toString()),
                                    onPressed: (){
                                      network.likeGame(logic.gameInfo!.id);
                                      logic.gameInfo!.isLiked = !logic.gameInfo!.isLiked;
                                      logic.update();
                                    },
                                  ),
                                  const SizedBox(width: 5,),
                                  ActionChip(
                                    avatar: const Icon(Icons.comment_outlined),
                                    label: Text(logic.gameInfo!.comments.toString()),
                                    onPressed: (){
                                      App.globalTo(()=>CommentsPage(logic.gameInfo!.id,type: "games",));
                                    },
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width-80,
                              child: FilledButton(
                                onPressed: (){
                                  gameDownload(context, logic.gameInfo!.link);
                                },
                                child: Text("下载".tl),
                              ),
                            )
                          ],
                        ),
                      )
                    ),
                  ),
                  if(MediaQuery.of(context).size.shortestSide>=changePoint)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          children: [
                            Expanded(
                              //flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Image(
                                    image: CachedImageProvider(
                                      logic.gameInfo!.icon
                                    ),
                                    fit: BoxFit.contain,
                                    width: MediaQuery.of(context).size.width/2-40,
                                    height: 390,
                                  ),
                                ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Text(logic.gameInfo!.name,style: const TextStyle(fontSize: 25),),
                                  Text(logic.gameInfo!.publisher,style: const TextStyle(fontSize: 16,color: Colors.blue),),
                                  SizedBox(
                                    height: 80,
                                    child: Row(
                                      children: [
                                        const Spacer(),
                                        Expanded(
                                          flex: 4,
                                          child: ActionChip(
                                            avatar: logic.gameInfo!.isLiked?const Icon(Icons.favorite):const Icon(Icons.favorite_border),
                                            label: Text(logic.gameInfo!.likes.toString()),
                                            onPressed: (){
                                              network.likeGame(logic.gameInfo!.id);
                                              logic.gameInfo!.isLiked = !logic.gameInfo!.isLiked;
                                              logic.update();
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: ActionChip(
                                            avatar: const Icon(Icons.comment_outlined),
                                            label: Text(logic.gameInfo!.comments.toString()),
                                            onPressed: (){
                                              App.globalTo(()=>CommentsPage(logic.gameInfo!.id,type: "games",));
                                            },
                                          ),
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width/2-80,
                                    child: FilledButton(
                                      onPressed: (){
                                        gameDownload(context, logic.gameInfo!.link);
                                      },
                                      child: Text("下载".tl),
                                    ),
                                  )
                                ],
                              )
                            )
                          ],
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: Divider(),),
                  SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
                    const SizedBox(width: 20,),
                    Icon(Icons.book, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 20,),
                    Text("简介".tl,style: const TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
                  ],)),),
                  const SliverPadding(padding: EdgeInsets.all(5)),
                  SliverToBoxAdapter(
                    child: Card(
                      elevation: 0,
                      //color: Theme.of(context).colorScheme.secondaryContainer,
                      margin: const EdgeInsets.all(5),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(logic.gameInfo!.description),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider(),),
                  SliverToBoxAdapter(child: SizedBox(width: 100,child: Row(children: [
                    const SizedBox(width: 20,),
                    Icon(Icons.camera, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 20,),
                    Text("屏幕截图".tl,style: const TextStyle(fontWeight: FontWeight.w500,fontSize: 16),)
                  ],)),),
                  const SliverPadding(padding: EdgeInsets.all(5)),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: Stack(
                        children: [
                          Positioned(
                            child: ListView(
                              controller: logic.controller,
                              scrollDirection: Axis.horizontal,
                              children: [
                                for(var s in logic.gameInfo!.screenshots)
                                  GestureDetector(
                                    child: Card(
                                      child: Image(
                                        image: CachedImageProvider(
                                            logic.gameInfo!.icon
                                        ),
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                    onTap: (){
                                      App.globalTo(()=>ShowImagePage(s));
                                    },
                                  )
                              ],
                            ),
                          ),
                          Positioned(
                            top: 135,
                            left: 5,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(Icons.chevron_left),
                              onPressed: (){
                                logic.controller.jumpTo(logic.controller.offset-200);
                              },
                            ),
                          ),
                          Positioned(
                            top: 135,
                            right: 5,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(Icons.chevron_right),
                              onPressed: (){
                                logic.controller.jumpTo(logic.controller.offset+200);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(App.globalContext!).padding.bottom))
                ],
              ),
            );
          }else{
            return Scaffold(
              appBar: AppBar(),
              body: Stack(
                children: [
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
                      child: Text("网络错误".tl),
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
                              logic.change();
                            },
                            child: Text("重试".tl),
                          ),
                        )
                    ),
                  ),
                ],
              ),
            );
          }
        },
    );
  }
}
