import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/dom.dart' as dom;
import 'package:pica_comic/comic_source/built_in/ehentai.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:pica_comic/components/components.dart';

class CommentsPageLogic extends StateController {
  bool isLoading = true;
  var comments = <Comment>[];
  bool sending = false;
  String? message;
  var controller = TextEditingController();

  void change() {
    isLoading = !isLoading;
    update();
  }

  void get(String url) async {
    var res = await EhNetwork().getComments(url);
    if (res.error) {
      message = res.errorMessageWithoutNull;
    } else {
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

  const CommentsPage(this.url, this.uploader, {Key? key, this.popUp = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget body = StateBuilder<CommentsPageLogic>(
      init: CommentsPageLogic(),
      builder: (logic) {
        if (logic.isLoading) {
          logic.get(url);
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (logic.message != null) {
          return NetworkError(
            message: logic.message!,
            retry: () => logic.change(),
            withAppbar: false,
          );
        } else {
          return Column(
            children: [
              Expanded(
                  child: CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildBuilderDelegate(
                          childCount: logic.comments.length, (context, index) {
                    var comment = logic.comments[index];
                    return Card(
                      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                      elevation: 0,
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${uploader == comment.name ? "(上传者)" : ""}${comment.name}",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 2,
                            ),
                            _EhComment(comment.content),
                            const SizedBox(
                              height: 4,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                TimeExtension.parseEhTime(comment.time)
                                    .toCompareString,
                                style: const TextStyle(fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  })),
                  SliverPadding(
                      padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(App.globalContext!).padding.bottom))
                ],
              )),
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16))),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
                  child: Material(
                    child: Container(
                      decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withAlpha(160),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(30))),
                      child: Row(
                        children: [
                          Expanded(
                              child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextField(
                              controller: logic.controller,
                              decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: "评论".tl),
                              minLines: 1,
                              maxLines: 5,
                            ),
                          )),
                          logic.sending
                              ? const Padding(
                                  padding: EdgeInsets.all(8.5),
                                  child: SizedBox(
                                    width: 23,
                                    height: 23,
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : IconButton(
                                  onPressed: () async {
                                    var content = logic.controller.text;
                                    if (content.isEmpty) {
                                      showToast(message: "请输入评论".tl);
                                      return;
                                    }
                                    logic.sending = true;
                                    logic.update();
                                    var b = await EhNetwork()
                                        .comment(logic.controller.text, url);
                                    if (b.success) {
                                      logic.controller.text = "";
                                      logic.sending = false;
                                      logic.comments.add(Comment(
                                          ehentai.data['name'] ?? '',
                                          content,
                                          DateTime.now().toIso8601String()));
                                      logic.update();
                                    } else {
                                      showToast(message: b.errorMessage!);
                                      logic.sending = false;
                                      logic.update();
                                    }
                                  },
                                  icon: Icon(
                                    Icons.send,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ))
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );

    if (popUp) {
      return body;
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("评论".tl),
        ),
        body: body,
      );
    }
  }
}

void showComments(BuildContext context, String url, String uploader) {
  showSideBar(
      context,
      CommentsPage(
        url,
        uploader,
        popUp: true,
      ),
      title: "评论".tl);
}

class _EhComment extends StatelessWidget {
  const _EhComment(this.html);

  final String html;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
        child: Column(
      children: _parse(html).toList(),
    ));
  }

  void onLink(String link) {
    if (canHandle(link)) {
      App.globalBack();
      handleAppLinks(Uri.parse(link));
    } else {
      launchUrlString(link);
    }
  }

  Iterable<Widget> _parse(String html) sync* {
    html = html.replaceAll("\r\n", "\n");
    html = html.replaceAll("<br>", "\n");
    var lines = html.split("\n");
    for (var line in lines) {
      yield SizedBox(
        width: double.infinity,
        child: _buildLine(line),
      );
    }
  }

  TextStyle _mergeStyleByTagName(TextStyle style, String tagName) {
    var richTextStyle = RichTextStyle.defaultStyle;
    switch (tagName) {
      case 'strong':
        style = style.merge(richTextStyle.strong!);
      case 'em':
        style = style.merge(richTextStyle.em!);
      case 'h1':
        style = style.merge(richTextStyle.h1!);
      case 'h2':
        style = style.merge(richTextStyle.h2!);
      case 'h3':
        style = style.merge(richTextStyle.h3!);
      case 'h4':
        style = style.merge(richTextStyle.h4!);
      case 'h5':
        style = style.merge(richTextStyle.h5!);
      case 'h6':
        style = style.merge(richTextStyle.h6!);
      default:
        style = style.merge(richTextStyle.paragraph!);
    }
    return style;
  }

  Widget _buildLine(String htmlText) {
    htmlText = htmlText.replaceAll('\n', '');
    var html = html_parser.parseFragment(htmlText);

    var widgets = <Widget>[];

    List<TextSpan> spans = [];

    void parse(dom.Node node, TextStyle style,
        [TapGestureRecognizer? recognizer]) {
      if (node is dom.Element) {
        if (node.localName == 'a') {
          recognizer = TapGestureRecognizer()
            ..onTap = () {
              onLink(node.attributes['href']!);
            };
        } else if (node.localName == 'img') {
          widgets.add(Text.rich(TextSpan(children: spans)));
          spans = [];
          Widget widget = Image(
            image: CachedImageProvider(node.attributes['src']!),
          );
          if (recognizer != null) {
            widget = MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: recognizer.onTap,
                child: widget,
              ),
            );
          }
          widgets.add(widget);
        } else {
          style = _mergeStyleByTagName(style, node.localName ?? '');
        }
        for (var child in node.nodes) {
          parse(child, style, recognizer);
        }
      } else if (node is dom.Text) {
        var text = node.text;
        var splits = text.split(' ');
        String buffer = '';
        for (var part in splits) {
          if (part.isURL) {
            if (buffer.isNotEmpty) {
              spans.add(TextSpan(text: buffer, style: style));
              buffer = '';
            }
            spans.add(TextSpan(
              text: part,
              style: style.copyWith(
                color: RichTextStyle.defaultStyle.link!.color,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  onLink(part);
                },
            ));
          } else {
            buffer += '$part ';
          }
        }
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer, style: style));
        }
      }
    }

    for (var node in html.nodes) {
      parse(node, const TextStyle());
    }

    if (spans.isNotEmpty) {
      widgets.add(Text.rich(TextSpan(children: spans)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class RichTextStyle {
  final TextStyle? h1;
  final TextStyle? h2;
  final TextStyle? h3;
  final TextStyle? h4;
  final TextStyle? h5;
  final TextStyle? h6;
  final TextStyle? paragraph;
  final TextStyle? link;
  final TextStyle? strong;
  final TextStyle? em;
  final Color? contentColor;

  const RichTextStyle._(
      {required this.h1,
      required this.h2,
      required this.h3,
      required this.h4,
      required this.h5,
      required this.h6,
      required this.paragraph,
      required this.link,
      required this.strong,
      required this.em})
      : contentColor = null;

  static const RichTextStyle defaultStyle = RichTextStyle._(
    h1: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
    h2: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    h3: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    h4: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    h5: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    h6: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    paragraph: TextStyle(
        fontSize: 16,
        wordSpacing: 1,
        letterSpacing: 0.2,
        height: 1.2,
        color: Color.fromARGB(255, 0, 0, 0)),
    link: TextStyle(color: Color.fromARGB(255, 0, 140, 255)),
    strong: TextStyle(fontWeight: FontWeight.bold),
    em: TextStyle(fontStyle: FontStyle.italic),
  );
}
