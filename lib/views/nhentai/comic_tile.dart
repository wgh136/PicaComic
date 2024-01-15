import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/animated_image.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import '../main_page.dart';
import '../widgets/loading.dart';
import '../widgets/show_message.dart';

class NhentaiComicTile extends ComicTile{
  final NhentaiComicBrief comic;

  const NhentaiComicTile(this.comic, {super.key});

  @override
  String get description => comic.lang;

  @override
  Widget get image => AnimatedImage(
    image: CachedImageProvider(
      comic.cover,
      headers: {
        "User-Agent": webUA,
      },
    ),
    fit: BoxFit.cover,
    height: double.infinity,
    width: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void onTap_() {
    MainPage.to(() => NhentaiComicPage(comic.id));
  }

  @override
  String get subTitle => "ID: ${comic.id}";

  @override
  String get title => comic.title;

  List<String> _generateTags(List<String> tags){
    if(App.locale.languageCode != "zh") {
      return tags;
    }
    var res = <String>[];
    for(var tag in tags){
      res.add(tag.translateTagsToCN);
    }
    return res;
  }

  @override
  List<String>? get tags => _generateTags(comic.tags);

  @override
  ActionFunc? get read => () async{
    bool cancel = false;
    showLoadingDialog(App.globalContext!, ()=>cancel=true);
    var res = await NhentaiNetwork().getComicInfo(comic.id);
    if(cancel){
      return;
    }
    if(res.error){
      App.globalBack();
      showMessage(App.globalContext, res.errorMessageWithoutNull);
    }else{
      App.globalBack();
      readNhentai(res.data);
    }
  };

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromNhentai(comic);

  @override
  String get comicID => comic.id;
}