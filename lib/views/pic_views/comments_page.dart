import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/models.dart';
import '../widgets/list_loading.dart';

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
      builder: (commentsPageLogic){
        if(commentsPageLogic.isLoading){
          network.getCommends(id,type: type).then((c){
            commentsPageLogic.comments = c;
            commentsPageLogic.change();
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(commentsPageLogic.comments.loaded==0){
          return showNetworkError(context, ()=>commentsPageLogic.change(),showBack: false);
        }else{
          return Column(
            children: [
              Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverList(delegate: SliverChildBuilderDelegate(
                          childCount: commentsPageLogic.comments.comments.length,
                              (context,index){
                            if(index==commentsPageLogic.comments.comments.length-1&&commentsPageLogic.comments.pages!=commentsPageLogic.comments.loaded){
                              network.loadMoreCommends(commentsPageLogic.comments, type: type).then((t){commentsPageLogic.update();});
                            }
                            return CommentTile(comment: commentsPageLogic.comments.comments[index],isReply: false,popUp: popUp,);

                          }
                      )),
                      if(commentsPageLogic.comments.loaded!=commentsPageLogic.comments.pages&&commentsPageLogic.comments.pages!=1)
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
                                  hintText: "评论"
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
                            var b = await network.comment(id, commentsPageLogic.controller.text, false);
                            if(b){
                              commentsPageLogic.controller.text = "";
                              commentsPageLogic.sending = false;
                              var res = await network.getCommends(id);
                              commentsPageLogic.comments = Comments([], id, 1, 1);
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
      return PopUpWidgetScaffold(
          title: "评论",
          body: body,
      );
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
