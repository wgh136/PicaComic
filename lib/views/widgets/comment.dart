import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/models.dart';
import '../comment_reply_page.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({Key? key,required this.comment,required this.isReply,this.isToReply,this.popUp=false}) : super(key: key);
  final Comment comment;
  final bool isReply;
  final bool? isToReply;
  final bool popUp;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  late final bool isReply = widget.isReply;
  late final Comment comment = widget.comment;
  late final bool? isToReply = widget.isToReply;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapUp: (details){
        showMenu(
          useRootNavigator: true,
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: const Text("复制"),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: comment.text));
                  showMessage(context, "评论内容已复制");
                },
              )
            ]
        );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isToReply==true||isReply?(){}:()=>Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ReplyPage(comment.id,comment,popUp: widget.popUp,))),
          onLongPress: (){
            Clipboard.setData(ClipboardData(text: comment.text));
            showMessage(context, "评论内容已复制");
          },
          child: Padding(
              padding: MediaQuery.of(context).size.width<600?const EdgeInsets.fromLTRB(15, 0, 10, 5):const EdgeInsets.all(10),
              child: MediaQuery.of(context).size.width>=changePoint?Row(
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
                          const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                          Text(
                            "${comment.time.substring(0,10)}  ${comment.time.substring(11,19)}",
                            style: const TextStyle(fontSize: 12.0,fontWeight: FontWeight.w100),
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
                                onPressed: ()=>Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ReplyPage(comment.id,comment,popUp: widget.popUp))),
                              ),
                            )
                        ],
                      ),
                    )
                ],
              ):Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: Row(
                          children: [
                            Center(child: Avatar(
                              size: 50,
                              avatarUrl: comment.avatarUrl,
                              frame: comment.frame,
                              couldBeShown: true,
                              name: comment.name,
                              slogan: comment.slogan,
                              level: comment.level,
                            )),
                            Expanded(child: Text(
                              comment.name,
                              style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold),
                              maxLines: 1,
                            )),
                          ],
                        ),
                      ),
                      Padding(padding: const EdgeInsets.only(left: 6),child: Text(comment.text, style: const TextStyle(fontSize: 14.0),),),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
                      Padding(padding: const EdgeInsets.only(left: 6),child: Text(
                        "${comment.time.substring(0,10)}  ${comment.time.substring(11,19)}  ${comment.reply}回复  ${comment.likes}喜欢",
                        style: const TextStyle(fontSize: 12.0,fontWeight: FontWeight.w100),
                      ),),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
                    ],
                  ),
                  ),
                  Tooltip(
                    message: "喜欢",
                    child: IconButton(
                      hoverColor: Colors.transparent,
                      icon: Icon((comment.isLiked)?Icons.favorite:Icons.favorite_border,size: 20,),
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
                ],
              )
          ),
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
            width: 400,
            child: Column(
              children: [
                Padding(padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),child: TextField(
                  maxLines: 5,
                  controller: logic.controller,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder()
                  ),
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