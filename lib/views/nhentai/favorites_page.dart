import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';


class NhentaiFavoritePage extends ComicsPage<NhentaiComicBrief>{
  const NhentaiFavoritePage({super.key});

  @override
  Future<Res<List<NhentaiComicBrief>>> getComics(int i){
    return NhentaiNetwork().getFavorites(i);
  }

  @override
  String? get tag => "Nhentai Favorites";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.nhentai;

  @override
  bool get withScaffold => false;

  @override
  bool get showBackWhenError => false;

  @override
  bool get showBackWhenLoading => false;

  @override
  bool get showTitle => false;

}