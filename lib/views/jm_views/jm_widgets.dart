import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/animated_image.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../foundation/image_loader/cached_image.dart';
import '../../network/jm_network/jm_image.dart';

import '../main_page.dart';
import '../widgets/loading.dart';

class JmComicTile extends ComicTile {
  final JmComicBrief comic;
  const JmComicTile(this.comic, {super.key});

  @override
  String get description => () {
        var categories = "";
        for (final category in comic.categories) {
          categories += "${category.name} ";
        }
        return categories;
      }.call();

  @override
  Widget get image => AnimatedImage(
    image: CachedImageProvider(
      getJmCoverUrl(comic.id),
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
    MainPage.to(() => JmComicPage(comic.id));
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.name;

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        showLoadingDialog(App.globalContext!, () => cancel = true);
        var res = await JmNetwork().getComicInfo(comic.id);
        if (cancel) {
          return;
        }
        if (res.error) {
          App.globalBack();
          showMessage(App.globalContext, res.errorMessageWithoutNull);
        } else {
          App.globalBack();
          readJmComic(res.data, res.data.series.values.toList());
        }
      };

  @override
  List<String>? get tags => comic.tags;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromJmComic(comic);
}
