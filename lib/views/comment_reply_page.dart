import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
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
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CommentTile(comment: replyTo, isReply: true, isToReply: true,),
              ),
              const SliverPadding(padding: EdgeInsets.all(2)),
              const SliverToBoxAdapter(child: Divider(),),
              SliverList(delegate: SliverChildBuilderDelegate(
                  childCount: commentsPageLogic.comments.comments.length,
                      (context,index){
                    if(index==commentsPageLogic.comments.comments.length-1&&commentsPageLogic.comments.total!=commentsPageLogic.comments.loaded){
                      network.getMoreReply(commentsPageLogic.comments).then((t){commentsPageLogic.update();});
                    }
                    return CommentTile(comment: commentsPageLogic.comments.comments[index], isReply: true);

                  }
              )),
              if(commentsPageLogic.comments.loaded!=commentsPageLogic.comments.total&&commentsPageLogic.comments.total!=1)
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
      },);

    var tailing = Tooltip(
      message: "发言",
      child: IconButton(
        icon: Icon(Icons.message,color: Theme.of(context).colorScheme.primary,),
        onPressed: (){
          giveComment(context, id, true).then((b){
            if(b){
              Get.find<ReplyPageLogic>().change();
            }
          });
        },
      ),
    );

    if(popUp){
      return PopUpWidgetScaffold(
          title: "回复",
          body: body,
          tailing: tailing,
      );
    }else{
      return Scaffold(
        appBar: AppBar(
          title: const Text("回复"),
          actions: [
            tailing
          ],
        ),
        body: body,
      );
    }
  }
}