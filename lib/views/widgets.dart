import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/category_comic_page.dart';
import 'comic_page.dart';

class ComicTile extends StatelessWidget {
  final ComicItemBrief comic;
  const ComicTile(this.comic,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        appdata.history.add(comic);
        if(appdata.history.length>100){
          appdata.history.removeAt(0);
        }
        appdata.writeData();
        Get.to(() => ComicPage(comic));
      },
        child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              flex: 0,
              child: CachedNetworkImage(
                imageUrl: comic.path,
                errorWidget: (context, url, error) => const Icon(Icons.error),
                width: 80,
            ),),
            SizedBox.fromSize(size: const Size(5,5),),
            Expanded(
              flex: 3,
              child: ComicDescription(
                title: comic.title,
                user: comic.author,
                likesCount: comic.likes,
              ),
            ),
            const Center(
              child: Icon(Icons.arrow_right),
            )
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
    required this.likesCount,
  });

  final String title;
  final String user;
  final int likesCount;

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
            maxLines: 1,
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
                Text(
                  '$likesCount likes',
                  style: TextStyle(
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

class CategoryTile extends StatelessWidget {
  final void Function() onTap;
  final CategoryItem categoryItem;
  const CategoryTile(this.categoryItem,this.onTap,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (){
          Get.to(()=>CategoryComicPage(categoryItem.title));
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                flex: 0,
                child: CachedNetworkImage(
                  imageUrl: categoryItem.path,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  height: 80,
                  width: 80,
                ),),
              SizedBox.fromSize(size: const Size(20,5),),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(categoryItem.title,style: const TextStyle(fontWeight: FontWeight.w600),),
                )
              ),
            ],
          ),
        )
    );
  }
}

void showMessage(context, String message){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    duration: const Duration(seconds: 1),
    content: Text(message),
  ));
}