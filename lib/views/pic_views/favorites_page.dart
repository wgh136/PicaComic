import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class FavoritesPage extends ComicsPage<ComicItemBrief>{
  const FavoritesPage({super.key});

  @override
  bool get centerTitle => false;

  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) {
    return network.getFavorites(i);
  }

  @override
  String? get tag => "Picacg Favorite Page";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.picacg;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;
}