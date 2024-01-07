import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';

void randomComic(String key) {
  switch (key) {
    case "nhentai":
      MainPage.to(() => const NhentaiComicPage(""));
    default:
      throw UnimplementedError();
  }
}
