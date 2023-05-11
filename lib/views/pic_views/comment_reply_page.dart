import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/picacg_network/models.dart';
import '../widgets/list_loading.dart';
import '../widgets/side_bar.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class ReplyPageLogic extends GetxController{
  bool isLoading = true;
  var comments = Reply("",0,1,[]);
  bool sending = false;
  var controller = TextEditingController();
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ReplyPage extends StatelessWidget {
  final String id;
  final Comment replyTo;
  final bool popUp;
  const ReplyPage(this.id,this.replyTo,{this.popUp=false,Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = GetBuilder<ReplyPageLogic>(
      init: ReplyPageLogic(),
      builder: (commentsPageLogic){
        if(commentsPageLogic.isLoading){
          network.getReply(id).then((c){
            commentsPageLogic.comments = c;
            commentsPageLogic.change();
          });
          return const Center(child: CircularProgressIndicator(),);
        }else if(commentsPageLogic.comments.loaded==0){
          return showNetworkError(context, ()=>commentsPageLogic.change(),showBack: false);
        } else{
          return Column(
            children: [
              Expanded(child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: CommentTile(
                      avatarUrl: replyTo.avatarUrl,
                      name: replyTo.name,
                      content: replyTo.text,
                      time: "${replyTo.time.substring(0,10)}  ${replyTo.time.substring(11,19)}",
                      slogan: replyTo.slogan,
                      level: replyTo.level,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.all(2)),
                  const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 15),child: Divider(),),),
                  SliverList(delegate: SliverChildBuilderDelegate(
                      childCount: commentsPageLogic.comments.comments.length,
                          (context,index){
                        if(index==commentsPageLogic.comments.comments.length-1&&commentsPageLogic.comments.total!=commentsPageLogic.comments.loaded){
                          network.getMoreReply(commentsPageLogic.comments).then((t){commentsPageLogic.update();});
                        }
                        var comment = commentsPageLogic.comments.comments[index];
                        var subInfo = "${comment.time.substring(0,10)}  ${comment.time.substring(11,19)}";
                        return CommentTile(
                          avatarUrl: comment.avatarUrl,
                          name: comment.name,
                          content: comment.text,
                          slogan: comment.slogan,
                          level: comment.level,
                          time: subInfo,
                          like: (){
                            network.likeOrUnlikeComment(comment.id);
                            comment.isLiked = ! comment.isLiked;
                            comment.isLiked?comment.likes++:comment.likes--;
                            commentsPageLogic.update();
                          },
                          likes: comment.likes,
                          liked: comment.isLiked,
                        );
                      }
                  )),
                  if(commentsPageLogic.comments.loaded!=commentsPageLogic.comments.total&&commentsPageLogic.comments.total!=1)
                    const SliverToBoxAdapter(
                      child: ListLoadingIndicator(),
                    ),
                  SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
                ],
              )),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Material(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(160),
                          borderRadius: const BorderRadius.all(Radius.circular(30))
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextField(
                              controller: commentsPageLogic.controller,
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "回复"
                              ),
                              minLines: 1,
                              maxLines: 5,
                            ),
                          )),
                          commentsPageLogic.sending?const Padding(
                            padding: EdgeInsets.all(8.5),
                            child: SizedBox(width: 23,height: 23,child: CircularProgressIndicator(),),
                          ):IconButton(onPressed: () async{
                            if(commentsPageLogic.controller.text.length<2){
                              showMessage(context, "评论至少需要2个字");
                              return;
                            }
                            commentsPageLogic.sending = true;
                            commentsPageLogic.update();
                            var b = await network.comment(id, commentsPageLogic.controller.text, true);
                            if(b){
                              commentsPageLogic.controller.text = "";
                              commentsPageLogic.sending = false;
                              var res = await network.getReply(id);
                              commentsPageLogic.comments = Reply(id,1,1,[]);
                              commentsPageLogic.update();
                              await Future.delayed(const Duration(milliseconds: 200));
                              commentsPageLogic.comments = res;
                              commentsPageLogic.update();
                            }else{
                              if(network.status){
                                showMessage(Get.context, network.message);
                              }else{
                                showMessage(Get.context, "网络错误");
                              }
                              commentsPageLogic.sending = false;
                              commentsPageLogic.update();
                            }
                          }, icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary,))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
            ],
          );
        }
      },);

    if(popUp){
      return body;
    }else{
      return Scaffold(
        appBar: AppBar(
          title: const Text("回复"),
        ),
        body: body,
      );
    }
  }
}

void showReply(BuildContext context, String id, Comment replyTo){
  showSideBar(context, ReplyPage(id, replyTo, popUp: true,), title: "回复", showBarrier: false);
}