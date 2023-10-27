import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../widgets/selectable_text.dart';
import '../widgets/side_bar.dart';

class CommentsPageLogic extends StateController{
  bool isLoading = true;
  var comments = <Comment>[];
  bool sending = false;
  String? message;
  var controller = TextEditingController();
  void change(){
    isLoading = !isLoading;
    update();
  }
  void get(String url) async{
    var res = await EhNetwork().getComments(url);
    if(res.error){
      message = res.errorMessageWithoutNull;
    }else{
      comments = res.data;
    }
    isLoading = false;
    update();
  }
}

class CommentsPage extends StatelessWidget {
  final String url;
  final String uploader;
  final bool popUp;
  const CommentsPage(this.url,this.uploader, {Key? key, this.popUp=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget body = StateBuilder<CommentsPageLogic>(
      init: CommentsPageLogic(),
      builder: (logic){
        if(logic.isLoading){
          logic.get(url);
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.message != null){
          return showNetworkError(logic.message!,
                  ()=>logic.change(), context, showBack: false);
        }else{
          return Column(
            children: [
              Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverList(delegate: SliverChildBuilderDelegate(
                          childCount: logic.comments.length,
                              (context,index){
                                var comment = logic.comments[index];
                                return Card(
                                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("${uploader==comment.name?"(上传者)":""}${comment.name}",style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w500),),
                                        const SizedBox(height: 2,),
                                        CustomSelectableText(text: comment.content)
                                      ],
                                    ),
                                  ),
                                );
                          }
                      )),
                      SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(App.globalContext!).padding.bottom))
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
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "评论".tl
                              ),
                              minLines: 1,
                              maxLines: 5,
                            ),
                          )),
                          logic.sending?const Padding(
                            padding: EdgeInsets.all(8.5),
                            child: SizedBox(width: 23,height: 23,child: CircularProgressIndicator(),),
                          ):IconButton(onPressed: () async{
                            var content = logic.controller.text;
                            if(content.isEmpty){
                              showMessage(context, "请输入评论".tl);
                              return;
                            }
                            logic.sending = true;
                            logic.update();
                            var b = await EhNetwork().comment(logic.controller.text, url);
                            if(b.success){
                              logic.controller.text = "";
                              logic.sending = false;
                              logic.comments.add(Comment(appdata.ehAccount, content, DateTime.now().toIso8601String()));
                              logic.update();
                            }else{
                              showMessage(App.globalContext, b.errorMessageWithoutNull);
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
            ],
          );
        }
      },);

    if(popUp){
      return body;
    }else{
      return Scaffold(
        appBar: AppBar(
          title: Text("评论".tl),
        ),
        body: body,
      );
    }
  }
}

void showComments(BuildContext context, String url, String uploader){
  showSideBar(context, CommentsPage(url, uploader, popUp: true,), title: "评论".tl);
}