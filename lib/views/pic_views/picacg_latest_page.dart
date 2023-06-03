import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

class PicacgLatestPage extends ComicsPage<ComicItemBrief>{
  const PicacgLatestPage({super.key});

  @override
  bool get centerTitle => true;

  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) {
    return network.getLatest(i);
  }

  @override
  bool get largeTitle => true;

  @override
  String? get tag => "Picacg Latest";

  @override
  String get title => "最新漫画";

  @override
  ComicType get type => ComicType.picacg;

  @override
  bool get withScaffold => true;

}