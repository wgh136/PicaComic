import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/stream_image_provider.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/views/custom_views/comic_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';

import '../widgets/animated_image.dart';

class CustomComicTile extends ComicTile {
  const CustomComicTile(this.comic, {super.key, this.addonMenuOptions});

  final CustomComic comic;

  @override
  String get description => comic.description;

  @override
  Widget get image => AnimatedImage(
        image: StreamImageProvider(
            () =>
                ImageManager().getCustomThumbnail(comic.cover, comic.sourceKey),
            comic.id),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  @override
  void onTap_() {
    MainPage.to(() => CustomComicPage(
          sourceKey: comic.sourceKey,
          id: comic.id,
          comicCover: comic.cover,
        ));
  }

  @override
  String get subTitle => comic.subTitle;

  @override
  String get title => comic.title;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.custom(comic);

  @override
  List<String>? get tags => comic.tags;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;

  @override
  String? get comicID => comic.id;
}
