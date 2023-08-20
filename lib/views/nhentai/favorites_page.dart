import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';


class NhentaiFavoritePage extends ComicsPage<NhentaiComicBrief>{
  const NhentaiFavoritePage({super.key});

  @override
  Future<Res<List<NhentaiComicBrief>>> getComics(int i) async{
    var res = await NhentaiNetwork().getFavorites();
    return Res(res.dataOrNull, subData: 1, errorMessage: res.errorMessage);
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

  @override
  bool get showPageIndicator => false;

}