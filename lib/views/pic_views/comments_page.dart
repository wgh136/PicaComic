import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/test/comment.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/models.dart';
import '../widgets/list_loading.dart';
import '../widgets/side_bar.dart';
import 'comment_reply_page.dart';

class CommentsPageLogic extends GetxController{
  bool isLoading = true;
  var comments = Comments([],"",0,0);
  bool sending = false;
  var controller = TextEditingController();
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class CommentsPage extends StatelessWidget {
  final String id;
  final String type;
  final bool popUp;
  const CommentsPage(this.id,{Key? key, this.type="comics", this.popUp=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget body = GetBuilder<CommentsPageLogic>(
      init: CommentsPageLogic(),
      builder: (logic){
        if(logic.isLoading){
          network.getCommends(id,type: type).then((c){
            logic.comments = c;
            logic.change();
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.comments.loaded==0){
          return showNetworkError(context, ()=>logic.change(),showBack: false);
        }else{
          return Column(
            children: [
              Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverList(delegate: SliverChildBuilderDelegate(
                          childCount: logic.comments.comments.length,
                              (context,index){
                            if(index==logic.comments.comments.length-1&&logic.comments.pages!=logic.comments.loaded){
                              network.loadMoreCommends(logic.comments, type: type).then((t){logic.update();});
                            }
                            var comment = logic.comments.comments[index];
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
                                logic.update();
                              },
                              likes: comment.likes,
                              liked: comment.isLiked,
                              comments: comment.reply,
                              onTap: ()=>showReply(context, comment.id, comment),
                            );
                          }
                      )),
                      if(logic.comments.loaded!=logic.comments.pages&&logic.comments.pages!=1)
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
                              controller: logic.controller,
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "评论"
                              ),
                              minLines: 1,
                              maxLines: 5,
                            ),
                          )),
                          logic.sending?const Padding(
                            padding: EdgeInsets.all(8.5),
                            child: SizedBox(width: 23,height: 23,child: CircularProgressIndicator(),),
                          ):IconButton(onPressed: () async{
                            if(logic.controller.text.length<2){
                              showMessage(context, "评论至少需要2个字");
                              return;
                            }
                            logic.sending = true;
                            logic.update();
                            var b = await network.comment(id, logic.controller.text, false);
                            if(b){
                              logic.controller.text = "";
                              logic.sending = false;
                              var res = await network.getCommends(id);
                              logic.comments = Comments([], id, 1, 1);
                              logic.update();
                              await Future.delayed(const Duration(milliseconds: 200));
                              logic.comments = res;
                              logic.update();
                            }else{
                              if(network.status){
                                showMessage(Get.context, network.message);
                              }else{
                                showMessage(Get.context, "网络错误");
                              }
                              logic.sending = false;
                              logic.update();
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
          title: const Text("评论"),
        ),
        body: body,
      );
    }
  }
}

void showComments(BuildContext context, String id){
  showSideBar(context, CommentsPage(id, popUp: true,), "评论",);
}