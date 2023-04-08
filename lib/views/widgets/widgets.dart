import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/category_comic_page.dart';
import 'package:pica_comic/views/widgets/cf_image_widgets.dart';
import '../comic_page.dart';

class ComicTile extends StatelessWidget {
  final ComicItemBrief comic;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  final String? time;
  final bool downloaded;
  const ComicTile(this.comic,{Key? key,this.onTap,this.size,this.time,this.onLongTap,this.cached=true,this.downloaded=false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap??(){
        Get.to(() => ComicPage(comic),preventDuplicates: false);
      },
        onLongPress: onLongTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: !downloaded?(cached?CfCachedNetworkImage(
                    imageUrl: getImageUrl(comic.path),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    height: double.infinity,
                  ):CfImageNetwork(
                    getImageUrl(comic.path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => const Icon(Icons.error),
                    height: double.infinity,
                  )):Image.file(
                    downloadManager.getCover(comic.id),
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                )
              ),
              SizedBox.fromSize(size: const Size(16,5),),
              Expanded(
                flex: 7,
                child: ComicDescription(
                  title: comic.title,
                  user: comic.author,
                  subDescription: time==null?(!downloaded?'${comic.likes} likes':"${size??"未知"} MB"):time!,
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
        borderRadius: BorderRadius.circular(16),
        onTap: (){
          Get.to(()=>CategoryComicPage(categoryItem.title,type: 1,));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16)
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CfCachedNetworkImage(
                    imageUrl: getImageUrl(categoryItem.path),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    fit: BoxFit.cover,
                  ),
                ),),
              SizedBox.fromSize(size: const Size(20,5),),
              Expanded(
                flex: 11,
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

void showMessage(context, String message, {int time=2}){
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