import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

class JmComicsPage extends ComicsPage<JmComicBrief>{
  const JmComicsPage(this.title, this.id, {super.key});

  @override
  final String title;

  final String id;

  @override
  Future<Res<List<JmComicBrief>>> getComics(int i) async{
    var res = await JmNetwork().getComicsPage(id, i);
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return Res(res.data.$1, subData: res.data.$2);
  }

  @override
  String? get tag => "Jm Comics Page $id";

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => true;

}
