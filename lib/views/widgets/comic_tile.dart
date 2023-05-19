import 'package:flutter/material.dart';
import 'package:get/get.dart';

///漫画组件
abstract class ComicTile extends StatelessWidget {
  const ComicTile({Key? key}) : super(key: key);

  Widget get image;
  Widget? buildSubDescription(BuildContext context) => null;
  String get title;
  String get subTitle;
  String get description;

  void favorite();

  void onLongTap_(){
    showDialog(context: Get.context!, builder: (context) => SimpleDialog(
      title: Text(title, maxLines: 3,),
      children: [
        const Divider(),
        const SizedBox(width: 400,),
        ListTile(
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text("阅读"),
          onTap: onTap_,
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_rounded),
          title: const Text("收藏/取消收藏"),
          onTap: (){
            Get.back();
            favorite();
          },
        ),
      ],
    ));
  }
  void onTap_();

  @override
  Widget build(BuildContext context) {
    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap_,
        onLongPress: onLongTap_,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16)
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: image
                  )
              ),
              SizedBox.fromSize(size: const Size(16,5),),
              Expanded(
                flex: 8,
                child: ComicDescription(
                  title: title,
                  user: subTitle,
                  description: description,
                  subDescription: buildSubDescription(context),
                ),
              ),
              //const Center(
              //  child: Icon(Icons.arrow_right),
              //)
            ],
          ),
        )
    );
  }
}

class ComicDescription extends StatelessWidget {
  const ComicDescription({super.key,
    required this.title,
    required this.user,
    required this.description,
    this.subDescription
  });

  final String title;
  final String user;
  final String description;
  final Widget? subDescription;

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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
            maxLines: 1,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if(subDescription != null)
                  subDescription!,
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}