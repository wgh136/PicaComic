import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';

class JmLatestPage extends ComicsPage<JmComicBrief>{
  const JmLatestPage({super.key});

  @override
  Future<Res<List<JmComicBrief>>> getComics(int i) {
    return JmNetwork().getLatest(i);
  }

  static const stateTag = "JM latest page";

  @override
  String? get tag => stateTag;

  @override
  String get title => throw UnimplementedError();

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;

  @override
  bool get showBackWhenLoading => false;
}
