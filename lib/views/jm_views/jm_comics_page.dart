import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

import '../../foundation/app.dart';
import '../settings/settings_page.dart';

class JmComicsPage extends ComicsPage<JmComicBrief>{
  const JmComicsPage(this.title, this.id, {super.key});

  @override
  final String title;

  final String id;

  @override
  Future<Res<List<JmComicBrief>>> getComics(int i) async{
    return JmNetwork().getCategoryComicsNew(id,
        ComicsOrder.values[int.parse(appdata.settings[16])], i);
  }

  @override
  String? get tag => "Jm Comics Page $id";

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => true;

  @override
  Widget? get tailing => IconButton(
    icon: const Icon(Icons.sort),
    onPressed: () => setJmComicsOrder(App.globalContext!).then((b) {
          if (!b) {
            refresh();
          }
        }),
  );
}
