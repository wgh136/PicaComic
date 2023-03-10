import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/category_comic_page.dart';
import '../comic_page.dart';

class ComicTile extends StatelessWidget {
  final ComicItemBrief comic;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  const ComicTile(this.comic,{Key? key,this.onTap,this.size,this.onLongTap,this.cached=true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap??(){
        while(true) {
          bool flag = true;
          for (var c in appdata.history) {
            if (c.id == comic.id) {
              appdata.history.remove(c);
              flag = false;
              break;
            }
          }
          if(flag) break;
        }
        appdata.history.add(comic);
        if(appdata.history.length>100){
          appdata.history.removeAt(0);
        }
        appdata.writeData();
        Get.to(() => ComicPage(comic),preventDuplicates: false);
      },
        onLongPress: onLongTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: onTap==null?(cached?CachedNetworkImage(
                  imageUrl: getImageUrl(comic.path),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  height: double.infinity,
                ):Image.network(
                  getImageUrl(comic.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, url, error) => const Icon(Icons.error),
                  height: double.infinity,
                )):Image.file(
                  downloadManager.getCover(comic.id),
                  fit: BoxFit.cover,
                  height: double.infinity,
                ),),
              SizedBox.fromSize(size: const Size(16,5),),
              Expanded(
                flex: 7,
                child: ComicDescription(
                  title: comic.title,
                  user: comic.author,
                  subDescription: onTap==null?'${comic.likes} likes':"${size??"??????"} MB",
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
    required this.subDescription,
  });

  final String title;
  final String user;
  final String subDescription;

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
                Text(
                  subDescription,
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

class CategoryTile extends StatelessWidget {
  final void Function() onTap;
  final CategoryItem categoryItem;
  const CategoryTile(this.categoryItem,this.onTap,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (){
          Get.to(()=>CategoryComicPage(categoryItem.title,type: 1,));
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: CachedNetworkImage(
                  imageUrl: getImageUrl(categoryItem.path),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  fit: BoxFit.fitWidth,
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

void showMessage(context, String message, {int time=1}){
  Get.showSnackbar(GetSnackBar(
    message: message,
    maxWidth: 350,
    snackStyle: SnackStyle.FLOATING,
    margin: const EdgeInsets.all(5),
    animationDuration: const Duration(microseconds: 400),
    borderRadius: 10,
    duration: Duration(seconds: time),
  ));
}

void hideMessage(context){
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
}