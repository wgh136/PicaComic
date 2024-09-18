import 'package:flutter/widgets.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/def.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/hitomi/hitomi_comic_page.dart';
import 'package:pica_comic/pages/hitomi/hitomi_home_page.dart';
import 'package:pica_comic/pages/hitomi/hitomi_search.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';

final hitomi = ComicSource.named(
  name: "hitomi",
  key: "hitomi",
  filePath: "built-in",
  comicTileBuilderOverride: (context, comic, options) {
    return _HiComicTile(
      comic as HitomiComicBrief,
      addonMenuOptions: options,
    );
  },
  explorePages: [
    ExplorePageData.named(
      title: "hitomi",
      type: ExplorePageType.override,
      overridePageBuilder: (context) => const HitomiHomePage(),
    ),
  ],
  searchPageData: SearchPageData.named(
    overrideSearchResultBuilder: (keyword, options) {
      return HitomiSearchPage(keyword);
    },
    enableLanguageFilter: true,
  ),
  comicPageBuilder: (context, id, cover) {
    return HitomiComicPage.fromLink(id, cover: cover);
  },
  getThumbnailLoadingConfig: (url) {
    return {
      "headers": {"User-Agent": webUA, "Referer": "https://hitomi.la/"},
    };
  },
);

class _HiComicTile extends ComicTile {
  final HitomiComicBrief comic;

  const _HiComicTile(this.comic, {this.addonMenuOptions});

  List<String> _generateTags(List<Tag> tags) {
    var res = <String>[];
    for (var tag in tags) {
      var name = tag.name;
      if (App.locale.languageCode == "zh") {
        if (name.contains('♀')) {
          name = "${name.replaceFirst(" ♀", "").translateTagsToCN}♀";
        } else if (name.contains('♂')) {
          name = "${name.replaceFirst(" ♂", "").translateTagsToCN}♂";
        } else {
          name = name.translateTagsToCN;
        }
      }
      res.add(name);
    }
    return res;
  }

  @override
  List<String>? get tags => _generateTags(comic.tagList);

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(App.globalContext!,
            onCancel: () => cancel = true);
        var res = await HiNetwork().getComicInfo(comic.link);
        if (cancel) {
          return;
        }
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
                () => ComicReadingPage.hitomi(
              res.data,
              comic.link,
              initialPage: history.page,
            ),
          );
        }
      };

  @override
  String get description => () {
        var description = "${comic.type}    ";
        description += comic.lang;
        return description;
      }.call();

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          comic.cover,
          headers: {"User-Agent": webUA, "Referer": "https://hitomi.la/"},
        ),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      );

  @override
  void onTap_() {
    App.mainNavigatorKey!.currentContext!.to(
      () => ComicPage(
        sourceKey: 'hitomi',
        id: comic.link,
        cover: comic.cover,
      ),
    );
  }

  @override
  String get subTitle => comic.artist;

  @override
  String get title => comic.name;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromHitomi(comic);

  @override
  String get comicID => comic.link;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;
}
