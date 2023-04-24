import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import '../widgets/avatar.dart';
import '../widgets/pop_up_widget_scaffold.dart';
import '../widgets/widgets.dart'
  show showMessage;

class JmCommentsPageLogic extends GetxController{
  bool loading = true;
  List<Comment>? comments;
  String? message;
  int totalComments = 0;
  int page = 1;

  void change(){
    loading = !loading;
    update();
  }

  void get(String id) async{
    var res = await jmNetwork.getComment(id, 1);
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      comments = res.data;
      totalComments = res.subData;
      change();
    }
  }

  void retry() async{
    message = null;
    comments = null;
    totalComments = 0;
    loading = true;
    page = 1;
    update();
  }

  void loadMore(String id) async{
    if(totalComments <= comments!.length){
      return;
    }
    var res = await jmNetwork.getComment(id, page+1);
    if(res.error){
      return;
    } else {
      page++;
      comments!.addAll(res.data);
      update();
    }
  }
}

class JmCommentsPage extends StatelessWidget {
  const JmCommentsPage(this.id, {this.popUp=false, Key? key}) : super(key: key);
  final String id;
  final bool popUp;

  @override
  Widget build(BuildContext context) {
    Widget body = GetBuilder<JmCommentsPageLogic>(
      init: JmCommentsPageLogic(),
      builder: (logic){
        if(logic.loading){
          logic.get(id);
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.comments == null){
          return showNetworkError(logic.message!, logic.retry, context);
        }else{
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: logic.comments!.length+1,
                  itemBuilder: (context, index){
                    if(index == logic.comments!.length-1){
                      logic.loadMore(id);
                    }
                    if(index == logic.comments!.length){
                      if(logic.totalComments >= logic.comments!.length){
                        return const SizedBox(
                          height: 30,
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 3,),
                            ),
                          ),
                        );
                      }else{
                        return const SizedBox(height: 0,);
                      }
                    }
                    return commentTile(logic.comments![index], context);
                  },
                ),
              ),

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
                          const Expanded(child: Padding(
                            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextField(
                              //controller: commentsPageLogic.controller,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "评论",
                              ),
                              minLines: 1,
                              maxLines: 5,
                              enabled: false,
                            ),
                          )),
                          IconButton(onPressed: () async{
                            //TODO
                            showMessage(context, "敬请期待");
                          }, icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary,))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
    });
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

Widget commentTile(Comment comment, BuildContext context){
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
                Clipboard.setData(ClipboardData(text: comment.content));
                showMessage(context, "评论内容已复制");
              },
            )
          ]
      );
    },
    child: Padding(
      padding: const EdgeInsets.fromLTRB(0, 1, 0, 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: ()=>showReply(context, comment.reply),
        onLongPress: (){
          Clipboard.setData(ClipboardData(text: comment.content));
          showMessage(context, "评论内容已复制");
        },
        child: Padding(
          padding: MediaQuery.of(context).size.width<600?const EdgeInsets.fromLTRB(15, 0, 10, 5):const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 60,
                width: double.infinity,
                child: Row(
                  children: [
                    Center(child: Avatar(
                      size: 50,
                      avatarUrl: comment.avatar,
                      frame: null,
                      couldBeShown: false,
                      name: comment.name,
                    )),
                    Expanded(child: Text(
                      comment.name,
                      style: const TextStyle(fontSize: 15,fontWeight: FontWeight.bold),
                      maxLines: 1,
                    )),
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.only(left: 6),child: Text(comment.content, style: const TextStyle(fontSize: 14.0),),),
              const Padding(padding: EdgeInsets.symmetric(vertical: 6.0)),
              Padding(padding: const EdgeInsets.only(left: 6),child: Text(
                "${comment.time}  ${comment.reply.length}回复",
                style: TextStyle(fontSize: 12.0, color: Theme.of(context).colorScheme.onSurface.withAlpha(220)),
              ),),
              const Padding(padding: EdgeInsets.symmetric(vertical: 4.0)),
            ],
          ),
        ),
      ),
    ),
  );
}

void showReply(BuildContext context, List<Comment> comments){
  if(comments.isEmpty)  return;
  showModalBottomSheet(isScrollControlled: true,context: context, builder: (context){
    return SizedBox(
      height: MediaQuery.of(context).size.height*0.9-60,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            width: double.infinity,
            child: Row(
              children: [
                if(Navigator.of(context).canPop())
                  Tooltip(
                    message: "返回",
                    child: IconButton(
                        icon: const Icon(Icons.arrow_back_sharp),
                        onPressed:()=>Navigator.of(context).pop()
                    ),
                  ),
                const SizedBox(width: 16,),
                const Text("回复",style: TextStyle(fontSize: 22,fontWeight: FontWeight.w500),),
                const Spacer(),
              ],
            ),
          ),
          Expanded(child: ListView.builder(
            itemCount: comments.length,
            itemBuilder: (context, index){
              return commentTile(comments[index], context);
            },
          ))
        ],
      ),
    );
  });
}