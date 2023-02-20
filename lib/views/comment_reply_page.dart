import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import '../network/models.dart';

class ReplyPageLogic extends GetxController{
  bool isLoading = true;
  var comments = Reply("",0,1,[]);
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ReplyPage extends StatelessWidget {
  final String id;
  final Comment replyTo;
  const ReplyPage(this.id,this.replyTo,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ReplyPageLogic>(
        init: ReplyPageLogic(),
        builder: (commentsPageLogic){
          if(commentsPageLogic.isLoading){
            network.getReply(id).then((c){
              commentsPageLogic.comments = c;
              commentsPageLogic.change();
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(commentsPageLogic.comments.loaded==0){
            return showNetworkError(context, () {commentsPageLogic.change();});
          } else{
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  centerTitle: true,
                  title: const Text("回复"),
                  actions: [
                    Tooltip(
                      message: "发言",
                      child: IconButton(
                        icon: Icon(Icons.message,color: Theme.of(context).colorScheme.primary,),
                        onPressed: (){
                          giveComment(context, id,true).then((b){
                            if(b){
                              commentsPageLogic.comments = Reply("",0,1,[]);
                              commentsPageLogic.change();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                    child: CommentTile(comment: replyTo, isReply: true, isToReply: true,),
                ),
                const SliverPadding(padding: EdgeInsets.all(10)),
                const SliverToBoxAdapter(child: Divider(),),
                SliverList(delegate: SliverChildBuilderDelegate(
                    childCount: commentsPageLogic.comments.comments.length,
                        (context,index){
                      if(index==commentsPageLogic.comments.comments.length-1&&commentsPageLogic.comments.total!=commentsPageLogic.comments.loaded){
                        network.getMoreReply(commentsPageLogic.comments).then((t){commentsPageLogic.update();});
                      }
                      return CommentTile(comment: commentsPageLogic.comments.comments[index], isReply: true);

                    }
                ))],
            );
          }
        },),
    );
  }
}