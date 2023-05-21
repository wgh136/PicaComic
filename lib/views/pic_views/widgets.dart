import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';
import 'package:pica_comic/views/widgets/cf_image_widgets.dart';
import '../widgets/comic_tile.dart';
import 'comic_page.dart';

///哔咔漫画块, 同时也是下载页面的漫画块
class PicComicTile extends ComicTile {
  final ComicItemBrief comic;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  final String? time;
  final bool downloaded;
  const PicComicTile(this.comic,{Key? key,this.onTap,this.size,this.time,this.onLongTap,this.cached=true,this.downloaded=false}) : super(key: key);

  @override
  String get description => time==null?(!downloaded?'${comic.likes} likes':"${size??"未知"} MB"):time!;

  @override
  Widget get image => !downloaded?(cached?CfCachedNetworkImage(
    imageUrl: getImageUrl(comic.path),
    fit: BoxFit.cover,
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    progressIndicatorBuilder: (context, s, p) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
  ):CfImageNetwork(
    getImageUrl(comic.path),
    fit: BoxFit.cover,
    errorBuilder: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
  )):Image.file(
    downloadManager.getCover(comic.id),
    fit: BoxFit.cover,
    height: double.infinity,
  );

  @override
  void favorite() {
    network.favouriteOrUnfavoriteComic(comic.id);
  }

  @override
  void onLongTap_() {
    if(onLongTap != null){
      onLongTap!();
    }else{
      super.onLongTap_();
    }
  }

  @override
  void onTap_() {
    if(onTap != null){
      onTap!();
    }else{
      Get.to(()=>ComicPage(comic));
    }
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.title;
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
                    progressIndicatorBuilder: (context, s, p) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
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