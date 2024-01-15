import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/animated_image.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../main_page.dart';
import '../widgets/comic_tile.dart';
import 'comic_page.dart';

///哔咔漫画块
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
  List<String>? get tags => comic.tags;

  @override
  Widget get image => !downloaded?(AnimatedImage(
    image: CachedImageProvider(
      comic.path,
    ),
    fit: BoxFit.cover,
    height: double.infinity,
    width: double.infinity,
    filterQuality: FilterQuality.medium,
  )):Image.file(
    downloadManager.getCover(comic.id),
    fit: BoxFit.cover,
    height: double.infinity,
  );

  @override
  ActionFunc? get read => () async{
    bool cancel = false;
    showLoadingDialog(App.globalContext!, ()=>cancel=true);
    var res = await network.getEps(comic.id);
    if(cancel){
      return;
    }
    if(res.error){
      App.globalBack();
      showMessage(App.globalContext, res.errorMessageWithoutNull);
    }else{
      App.globalBack();
      readPicacgComic2(comic, res.data);
    }
  };

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
      MainPage.to(()=>PicacgComicPage(comic));
    }
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.title;

  @override
  int? get pages => comic.pages;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromPicacg(comic);

  @override
  String get comicID => comic.id;
}
