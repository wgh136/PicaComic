import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../main_page.dart';
import '../../widgets/loading.dart';

class EhGalleryTile extends ComicTile{
  final EhGalleryBrief gallery;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  final String? time;
  const EhGalleryTile(this.gallery,{Key? key,this.onTap,this.size,this.time,this.onLongTap,this.cached=true}) : super(key: key);

  List<String> _generateTags(List<String> tags){
    if(PlatformDispatcher.instance.locale.languageCode != "zh") {
      return tags;
    }
    List<String> res = [];
    List<String> res2 = [];
    for(var tag in tags){
      if(tag.contains(":")){
        var splits = tag.split(":");
        if(splits[0] == "language"){
          continue;
        }
        var lowLevelKey = ["character", "artist", "cosplayer", "group"];
        if(lowLevelKey.contains(splits[0])){
          res2.add(TagsTranslation.translationTagWithNamespace(splits[1], splits[0]));
        }else {
          res.add(TagsTranslation.translationTagWithNamespace(splits[1], splits[0]));
        }
      }else{
        res.add(tag.translateTagsToCN);
      }
    }
    return res+res2;
  }

  @override
  int get maxLines => MediaQuery.of(Get.context!).size.width < 430 ? 1 : 2;

  @override
  ActionFunc? get read => () async{
    bool cancel = false;
    showLoadingDialog(Get.context!, ()=>cancel=true);
    var res = await EhNetwork().getGalleryInfo(gallery.link);
    if(cancel){
      return;
    }
    if(res.error){
      Get.back();
      showMessage(Get.context, res.errorMessageWithoutNull);
    }else{
      Get.back();
      readEhGallery(res.data);
    }
  };

  @override
  List<String>? get tags => _generateTags(gallery.tags);

  @override
  String get description => "${gallery.time}  ${gallery.type}";

  @override
  String? get badge => (){
    String? lang;
    if(gallery.tags.isNotEmpty&&gallery.tags[0].substring(0,4) == "lang"){
      lang = gallery.tags[0].substring(9);
    }else if(gallery.tags.length > 1 && gallery.tags.isNotEmpty&&gallery.tags[1].substring(0,4) == "lang"){
      lang = gallery.tags[1].substring(9);
    }
    if(PlatformDispatcher.instance.locale.languageCode == "zh" && lang != null){
      lang = lang.translateTagsToCN;
    }
    return lang;
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
      "User-Agent": webUA,
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
      "User-Agent": webUA,
      "Referer": EhNetwork().ehBaseUrl,
    },
  );

  @override
  void onTap_() {
    MainPage.to(() => EhGalleryPage(gallery));
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

  @override
  int? get pages => gallery.pages;
}