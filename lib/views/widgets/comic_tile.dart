import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../base.dart';
export 'package:pica_comic/foundation/def.dart';


abstract class ComicTile extends StatelessWidget {
  /// Show a comic brief information. Usually displayed in comic list page.
  const ComicTile({Key? key}) : super(key: key);

  Widget get image;
  Widget? buildSubDescription(BuildContext context) => null;
  String get title;
  String get subTitle;
  String get description;
  String? get badge => null;
  List<String>? get tags => null;
  int get maxLines => 2;

  ActionFunc? get favorite => null;

  ActionFunc? get read => null;

  bool get enableLongPressed => true;

  int? get pages => null;

  void onLongTap_() {
    showDialog(
        context: Get.context!,
        builder: (context) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        title.replaceAll("\n", ""),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.article),
                      title: Text("查看详情".tl),
                      onTap: (){
                        Get.back();
                        onTap_();
                      },
                    ),
                    if(favorite != null)
                      ListTile(
                        leading: const Icon(Icons.bookmark_rounded),
                        title: Text("收藏/取消收藏".tl),
                        onTap: () {
                          Get.back();
                          favorite!();
                        },
                      ),
                    if(read != null)
                      ListTile(
                        leading: const Icon(Icons.chrome_reader_mode),
                        title: Text("阅读".tl),
                        onTap: () {
                          Get.back();
                          read!();
                        },
                      ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            ));
  }

  void onTap_();
  void onSecondaryTap_(TapDownDetails details) {
    showMenu(
        context: Get.context!,
        position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy),
        items: [
          PopupMenuItem(
              onTap: () => Future.delayed(
                  const Duration(milliseconds: 200), () => onTap_()),
              child: Text("查看".tl)),
          if(read != null)
          PopupMenuItem(
              onTap: () => Future.delayed(
                  const Duration(milliseconds: 200), () => read!()),
              child: Text("阅读".tl)),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    if(appdata.settings[44] == "0"){
      return _buildDetailedMode(context, 3, 10);
    } else if(appdata.settings[44] == "3") {
      return _buildDetailedMode(context, 5, 12);
    }else{
      return _buildBriefMode(context);
    }
  }

  Widget _buildDetailedMode(BuildContext context, int flexLeft, int flexRight){
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap_,
          onLongPress: enableLongPressed ? onLongTap_ : null,
          onSecondaryTapDown: onSecondaryTap_,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
            child: Row(
              children: [
                Expanded(
                    flex: flexLeft,
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: image)),
                SizedBox.fromSize(
                  size: const Size(16, 5),
                ),
                Expanded(
                  flex: flexRight,
                  child: _ComicDescription(
                    //标题中不应出现换行符, 爬虫可能多爬取换行符, 为避免麻烦, 直接在此处删去
                    title: pages == null ? title.replaceAll("\n", "") : "[${pages}P]${title.replaceAll("\n", "")}",
                    user: subTitle,
                    description: description,
                    subDescription: buildSubDescription(context),
                    badge: badge,
                    tags: tags,
                    maxLines: maxLines,
                  ),
                ),
                //const Center(
                //  child: Icon(Icons.arrow_right),
                //)
              ],
            ),
          )),
    );
  }

  Widget _buildBriefMode(BuildContext context){
    return Material(
      color: Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap_,
          onLongPress: enableLongPressed ? onLongTap_ : null,
          onSecondaryTapDown: onSecondaryTap_,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: image),
                ),
                const SizedBox(height: 2,),
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, ),
                Text(subTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11),)
              ],
            ),
          )),
    );
  }
}

class _ComicDescription extends StatelessWidget {
  const _ComicDescription(
      {required this.title,
      required this.user,
      required this.description,
      this.subDescription,
      this.badge,
      this.maxLines=2,
      this.tags});

  final String title;
  final String user;
  final String description;
  final Widget? subDescription;
  final String? badge;
  final List<String>? tags;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          if(user != "")
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
            maxLines: 1,
          ),
          if(user != "")
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const SizedBox(
                  height: 5,
                ),
                if (tags != null)
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => Padding(
                        padding:
                            EdgeInsets.only(bottom: constraints.maxHeight % 23),
                        child: Wrap(
                          runAlignment: WrapAlignment.start,
                          clipBehavior: Clip.antiAlias,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            for (var s in tags!)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 4, 3),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(3, 1, 3, 3),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8)),
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subDescription != null) subDescription!,
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                        ),
                        child: Text(badge!, style: const TextStyle(fontSize: 13),),
                      )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
