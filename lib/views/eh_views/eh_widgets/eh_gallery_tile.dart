import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class EhGalleryTile extends ComicTile{
  final EhGalleryBrief gallery;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  final String? time;
  const EhGalleryTile(this.gallery,{Key? key,this.onTap,this.size,this.time,this.onLongTap,this.cached=true}) : super(key: key);

  @override
  List<String>? get tags => gallery.tags.sublist(0,min(gallery.tags.length, 20)).map<String>((e){var value = e.contains(":")?e.split(":")[1]:e;return value.length>10?"${value.substring(0,10)}...":value;}).toList();

  @override
  void favorite() {
    showMessage(Get.context, "暂未实现, 请在漫画详情页收藏");
  }

  @override
  String get description => (){
    var lang = "";
    if(gallery.tags.isNotEmpty&&gallery.tags[0].substring(0,4) == "lang"){
      lang = gallery.tags[0].substring(9);
    }
    return "${gallery.time}  ${gallery.type}  $lang";
  }.call();

  @override
  Widget get image => cached?CachedNetworkImage(
    useOldImageOnUrlChange: true,
    imageUrl: gallery.coverPath,
    fit: BoxFit.cover,
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    httpHeaders: {
      "Cookie": EhNetwork().cookiesStr,
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
      "Referer": EhNetwork().ehBaseUrl,
    },
  ):Image.network(
    gallery.coverPath,
    fit: BoxFit.cover,
    errorBuilder: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    frameBuilder: (BuildContext context, Widget child, int? frame, bool? wasSynchronouslyLoaded) {
      return ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant, child: child,);
    },
    headers: {
      "Cookie": EhNetwork().cookiesStr,
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
      "Referer": EhNetwork().ehBaseUrl,
    },
  );

  @override
  void onTap_() {
    Get.to(() => EhGalleryPage(gallery), preventDuplicates: false);
  }

  @override
  Widget? buildSubDescription(context){
    final s = gallery.stars ~/ 0.5;
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          for(int i=0;i<s~/2;i++)
            Icon(Icons.star,size: 20,color: Theme.of(context).colorScheme.secondary,),
          if(s%2==1)
            Icon(Icons.star_half,size: 20,color: Theme.of(context).colorScheme.secondary,),
          for(int i=0;i<(5 - s~/2 - s%2);i++)
            const Icon(Icons.star_border,size: 20,)
        ],
      ),
    );
  }

  @override
  String get subTitle => gallery.uploader;

  @override
  String get title => gallery.title;

}