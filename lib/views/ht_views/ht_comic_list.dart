import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

class HtComicList extends ComicsPage<HtComicBrief>{
  const HtComicList({required this.name, required this.url, super.key});

  final String name;

  final String url;


  @override
  Future<Res<List<HtComicBrief>>> getComics(int i) {
    return HtmangaNetwork().getComicList("${HtmangaNetwork.baseUrl}$url", i);
  }

  @override
  String? get tag => "Ht ComicList $name";

  @override
  String get title => name;

  @override
  ComicType get type => ComicType.htManga;

  @override
  bool get withScaffold => true;

}