import 'package:pica_comic/views/ht_views/ht_comic_list.dart';
import 'package:pica_comic/views/jm_views/jm_comics_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';

import '../custom_views/category_comics_page.dart';

void toCategoryPage(String key, String tag, String? param) {
  switch (key) {
    case "picacg":
      MainPage.to(() => PicacgCategoryComicPage(
            tag,
          ));
    case "jm":
      MainPage.to(() => JmComicsPage(tag, param!));
    case "htmanga":
      MainPage.to(() => HtComicList(name: tag, url: param!));
    default:
      MainPage.to(() => CategoryComicsPage(
            category: tag,
            param: param,
            sourceKey: key,));
  }
}
