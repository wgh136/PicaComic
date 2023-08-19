import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../widgets/comment.dart';
import '../widgets/side_bar.dart';


class NhentaiCommentsPage extends StatefulWidget {
  const NhentaiCommentsPage(this.id, {super.key});

  final String id;

  @override
  State<NhentaiCommentsPage> createState() => _NhentaiCommentsPageState();
}

class _NhentaiCommentsPageState extends State<NhentaiCommentsPage> {
  bool loading = true;
  List<NhentaiComment>? comments;
  String? message;
  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if(loading){
      get();
      return const Center(
        child: CircularProgressIndicator(),
      );
    }else if(message != null){
      return showNetworkError(message, () => setState(() {
        loading = false;
        message = null;
        comments = null;
      }), context);
    }else{
      return Column(
        children: [
          Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildBuilderDelegate(childCount: comments!.length,
                              (context, index) {
                            return CommentTile(
                              avatarUrl: comments![index].avatar,
                              name: comments![index].userName,
                              content: comments![index].content,
                            );
                          })),
                  SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.bottom))
                ],
              )),
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceTint.withAlpha(0),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(160),
                    borderRadius: const BorderRadius.all(Radius.circular(30))),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: TextField(
                            enabled: false,
                            controller: controller,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isCollapsed: true,
                              hintText: "评论".tl,
                            ),
                            minLines: 1,
                            maxLines: 5,
                          ),
                        )),
                    IconButton(
                        onPressed: () {
                          //TODO
                          showMessage(context, "未完成");
                        },
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.secondary,
                        ))
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  void get() async{
    var res = await NhentaiNetwork().getComments(widget.id);
    setState(() {
      loading = false;
      if(res.error){
        message = res.errorMessageWithoutNull;
      }else{
        comments = res.data;
      }
    });
  }
}

void showComments(BuildContext context, String id) {
  showSideBar(
      context,
      NhentaiCommentsPage(id),
      title: "评论".tl);
}
