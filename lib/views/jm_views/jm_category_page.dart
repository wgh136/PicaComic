import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import 'package:pica_comic/views/settings/jm_settings.dart';
import 'package:pica_comic/tools/translations.dart';

class JmCategoryPage extends ComicsPage<JmComicBrief>{
  final Category category;
  final bool fromHomePage;
  const JmCategoryPage(this.category, {this.fromHomePage=false, super.key});

  @override
  Future<Res<List<JmComicBrief>>> getComics(int i) {
    ComicsOrder order;
    if(fromHomePage){
      order = ComicsOrder.latest;
    }else{
      order = ComicsOrder.values[int.parse(appdata.settings[16])];
    }
    return JmNetwork().getCategoryComicsNew(category.slug, order, i);
  }

  @override
  String? get tag => "JmCategory ${category.slug}";

  @override
  String get title => category.name;

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => true;

  @override
  Widget? get tailing => fromHomePage?null:Tooltip(
    message: "选择漫画排序模式".tl,
    child: IconButton(
      icon: const Icon(Icons.manage_search_outlined),
      onPressed: () async{
        var res = await setJmComicsOrder(Get.context!);
        if(!res) {
          super.refresh();
        }
      },
    ),
  );
}