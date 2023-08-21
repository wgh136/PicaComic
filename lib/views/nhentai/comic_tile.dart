import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:get/get.dart';
import '../main_page.dart';
import '../widgets/loading.dart';
import '../widgets/show_message.dart';

class NhentaiComicTile extends ComicTile{
  final NhentaiComicBrief comic;

  const NhentaiComicTile(this.comic, {super.key});

  @override
  String get description => comic.lang;

  @override
  Widget get image => CachedNetworkImage(
    imageUrl: comic.cover,
    fit: BoxFit.cover,
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void onTap_() {
    MainPage.to(() => NhentaiComicPage(comic.id));
  }

  @override
  String get subTitle => "";

  @override
  String get title => comic.title;

  @override
  int get maxLines => 4;

  @override
  ActionFunc? get read => () async{
    bool cancel = false;
    showLoadingDialog(Get.context!, ()=>cancel=true);
    var res = await NhentaiNetwork().getComicInfo(comic.id);
    if(cancel){
      return;
    }
    if(res.error){
      Get.back();
      showMessage(Get.context, res.errorMessageWithoutNull);
    }else{
      Get.back();
      readNhentai(res.data);
    }
  };
}