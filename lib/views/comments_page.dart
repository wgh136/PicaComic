import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import '../network/models.dart';

class CommentsPageLogic extends GetxController{
  bool isLoading = true;
  var comments = Comments([],"",0,0);
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class CommentsPage extends StatelessWidget {
  final String id;
  final String type;
  const CommentsPage(this.id,{Key? key, this.type="comics"}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CommentsPageLogic>(
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
        }else{
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                centerTitle: true,
                title: const Text("评论"),
                actions: [
                  Tooltip(
                    message: "发言",
                    child: IconButton(
                      icon: const Icon(Icons.message_sharp),
                      onPressed: (){
                        giveComment(context, id, false,type: type).then((b){
                          if(b){
                            commentsPageLogic.comments = Comments([],"",0,0);
                            commentsPageLogic.change();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              SliverList(delegate: SliverChildBuilderDelegate(
                childCount: commentsPageLogic.comments.comments.length,
                  (context,index){
                    if(index==commentsPageLogic.comments.comments.length-1&&commentsPageLogic.comments.pages!=commentsPageLogic.comments.loaded){
                      network.loadMoreCommends(commentsPageLogic.comments, type: type).then((t){commentsPageLogic.update();});
                    }
                    return CommentTile(comment: commentsPageLogic.comments.comments[index],isReply: false,);

                  }
          ))],
          );
        }
      },),
    );
  }
}
