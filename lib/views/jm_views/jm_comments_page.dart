import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import 'package:pica_comic/views/widgets/comment.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import '../../jm_network/jm_main_network.dart';
import '../widgets/widgets.dart' show showMessage;

class JmCommentsPageLogic extends GetxController {
  bool loading = true;
  List<Comment>? comments;
  String? message;
  int totalComments = 0;
  int page = 1;

  void change() {
    loading = !loading;
    update();
  }

  void get(String id) async {
    var res = await jmNetwork.getComment(id, 1);
    if (res.error) {
      message = res.errorMessage;
      change();
    } else {
      comments = res.data;
      totalComments = res.subData;
      change();
    }
  }

  void retry() async {
    message = null;
    comments = null;
    totalComments = 0;
    loading = true;
    page = 1;
    update();
  }

  void loadMore(String id) async {
    if (totalComments <= comments!.length) {
      return;
    }
    var res = await jmNetwork.getComment(id, page + 1);
    if (res.error) {
      return;
    } else {
      page++;
      comments!.addAll(res.data);
      update();
    }
  }
}

class JmCommentsPage extends StatelessWidget {
  const JmCommentsPage(this.id, {this.popUp = false, Key? key}) : super(key: key);
  final String id;
  final bool popUp;

  @override
  Widget build(BuildContext context) {
    Widget body = GetBuilder<JmCommentsPageLogic>(
        init: JmCommentsPageLogic(),
        builder: (logic) {
          if (logic.loading) {
            logic.get(id);
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (logic.comments == null) {
            return showNetworkError(logic.message!, logic.retry, context);
          } else {
            return Column(
              children: [
                Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverList(
                            delegate: SliverChildBuilderDelegate(childCount: logic.comments!.length,
                                (context, index) {
                          if (index == logic.comments!.length - 1) {
                            logic.loadMore(id);
                          }
                          return CommentTile(
                            avatarUrl: logic.comments![index].avatar,
                            name: logic.comments![index].name,
                            content: logic.comments![index].content,
                            comments: logic.comments![index].reply.length,
                            onTap: () => showReply(
                                context, logic.comments![index].reply, logic.comments![index]),
                            time: logic.comments![index].time,
                          );
                        })),
                        if (logic.totalComments > logic.comments!.length)
                          const SliverToBoxAdapter(
                            child: ListLoadingIndicator(),
                          ),
                        SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
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
                          const Expanded(
                              child: Padding(
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
                          IconButton(
                              onPressed: () async {
                                //TODO
                                showMessage(context, "敬请期待");
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
        });
    if (popUp) {
      return body;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text("评论"),
        ),
        body: body,
      );
    }
  }
}

void showReply(BuildContext context, List<Comment> comments, Comment replyTo) {
  if (comments.isEmpty) return;
  showSideBar(
      context,
      SingleChildScrollView(
        child: Column(
          children: [
            CommentTile(
              avatarUrl: replyTo.avatar,
              name: replyTo.name,
              content: replyTo.content,
              time: replyTo.time,
            ),
            const Divider(),
            for (int index = 0; index < comments.length; index++)
              CommentTile(
                avatarUrl: comments[index].avatar,
                name: comments[index].name,
                content: comments[index].content,
                time: comments[index].time,
              )
          ],
        ),
      ),
      title: "回复",
      showBarrier: false);
}

void showComments(BuildContext context, String id) {
  showSideBar(
      context,
      JmCommentsPage(
        id,
        popUp: true,
      ),
      title: "评论");
}
