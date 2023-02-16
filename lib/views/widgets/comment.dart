import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/models.dart';
import '../comment_reply_page.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({Key? key,required this.comment,required this.isReply,this.isToReply}) : super(key: key);
  final Comment comment;
  final bool isReply;
  final bool? isToReply;

  @override
  State<CommentTile> createState() => _CommentTileState(comment: comment, isReply: isReply, isToReply: isToReply);
}

class _CommentTileState extends State<CommentTile> {
  _CommentTileState({required this.comment,required this.isReply,this.isToReply});
  final bool isReply;
  final Comment comment;
  final bool? isToReply;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Expanded(
              flex: 0,
              child: Center(child: Avatar(
                size: 60,
                avatarUrl: comment.avatarUrl,
                frame: comment.frame,
                couldBeShown: true,
                name: comment.name,
                slogan: comment.slogan,
                level: comment.level,
              )),
            ),
            SizedBox.fromSize(size: const Size(10,5),),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  //mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      comment.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 18.0,
                      ),
                      maxLines: 1,
                    ),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                    Text(
                      comment.text,
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
            ),
            if(isToReply!=true)
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: ActionChip(
                      side: BorderSide.none,
                      label: Text(comment.likes.toString()),
                      avatar: Icon((comment.isLiked)?Icons.favorite:Icons.favorite_border),
                      onPressed: (){
                        network.likeOrUnlikeComment(comment.id);
                        setState(() {
                          comment.isLiked = !comment.isLiked;
                          if(comment.isLiked) {
                            comment.likes++;
                          }else{
                            comment.likes--;
                          }
                        });
                      },
                    ),
                  ),
                  if(!isReply)
                  SizedBox(
                    width: 80,
                    height: 40,
                    child: ActionChip(
                      side: BorderSide.none,
                      label: Text(comment.reply.toString()),
                      avatar: const Icon(Icons.comment_outlined),
                      onPressed: (){Get.to(()=>ReplyPage(comment.id,comment));},
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class GiveCommentController extends GetxController{
  bool isUploading = false;
  int status = 0;
  var controller = TextEditingController();
}

Future<bool> giveComment(BuildContext context, String id, bool isReply, {String type = "comics"}) async{
  bool res = false;
  await showDialog(context: context, builder: (context){
    return GetBuilder<GiveCommentController>(
      init: GiveCommentController(),
        builder: (logic){
      return SimpleDialog(
        title: const Text("发表评论"),
        children: [
          SizedBox(
            width: Get.size.width*0.75,
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),child: TextField(
                  controller: logic.controller,
                  keyboardType: TextInputType.text,
                ),),
                const SizedBox(height: 30,),
                if(!logic.isUploading)
                  FilledButton(onPressed: (){
                    if(logic.controller.text.length<=1){
                      logic.status = 3;
                      logic.update();
                      return;
                    }
                    logic.isUploading = true;
                    logic.update();
                    network.comment(id, logic.controller.text, isReply, type: type).then((b){
                      logic.isUploading = false;
                      if(b){
                        showMessage(context, "成功发表评论");
                        res = true;
                        Get.back();
                      }else{
                        network.status?logic.status=2:logic.status=1;
                      }
                      logic.update();
                    });
                  }, child: const Text("发布")),
                if(logic.isUploading)
                  const CircularProgressIndicator(),
                if(!logic.isUploading&&logic.status==1)
                  SizedBox(
                      width: 90,
                      height: 50,
                      child: Row(
                        children: const [
                          Icon(Icons.error),
                          Spacer(),
                          Text("网络错误")
                        ],
                      )
                  ),
                if(!logic.isUploading&&logic.status==2)
                  SizedBox(
                      width: 130,
                      height: 50,
                      child: Row(
                        children: const [
                          Icon(Icons.error),
                          Spacer(),
                          Text("没有评论权限")
                        ],
                      )
                  ),
                if(!logic.isUploading&&logic.status==3)
                  SizedBox(
                      width: 150,
                      height: 50,
                      child: Row(
                        children: const [
                          Icon(Icons.error),
                          Spacer(),
                          Text("评论字数需要大于1")
                        ],
                      )
                  ),
              ],
            ),
          )
        ],
      );
    });
  });
  return res;
}