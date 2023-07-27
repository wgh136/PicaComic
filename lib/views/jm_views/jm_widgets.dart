import 'package:cached_network_image/cached_network_image.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../network/jm_network/jm_image.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';

class JmComicTile extends ComicTile {
  final JmComicBrief comic;
  const JmComicTile(this.comic, {super.key});

  @override
  String get description => (){
    var categories = "";
    for(final category in comic.categories){
      categories += "${category.name} ";
    }
    return categories;
  }.call();

  @override
  Widget get image => CachedNetworkImage(
    imageUrl: getJmCoverUrl(comic.id),
    fit: BoxFit.cover,
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void favorite() {
    jmNetwork.favorite(comic.id).then((res){
      if(res.error){
        showMessage(Get.context, res.errorMessage!);
      }else{
        showMessage(Get.context, res.data?"添加收藏成功".tl:"取消收藏成功".tl);
      }
    });
  }

  @override
  void onTap_() {
    Get.to(() => JmComicPage(comic.id), preventDuplicates: false);
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.name;


}