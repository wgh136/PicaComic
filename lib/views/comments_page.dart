import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
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
        }else if(commentsPageLogic.comments.loaded==0){
          return showNetworkError(context, () {commentsPageLogic.change();});
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
                      icon: Icon(Icons.message,color: Theme.of(context).colorScheme.primary,),
                      onPressed: (){
                        giveComment(context, id, false,type: type).then((b){
                          if(b){
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
          )),
              if(commentsPageLogic.comments.loaded!=commentsPageLogic.comments.pages&&commentsPageLogic.comments.pages!=1)
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 80,
                  child: const Center(
                    child: SizedBox(
                      width: 20,height: 20,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
            ],
          );
        }
      },),
    );
  }
}
