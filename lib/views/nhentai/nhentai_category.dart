import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

import '../../base.dart';
import '../../foundation/app.dart';

class NhentaiCategory extends ComicsPage<NhentaiComicBrief> {
  final String path;

  const NhentaiCategory(this.path, {Key? key}) : super(key: key);

  @override
  Future<Res<List<NhentaiComicBrief>>> getComics(int i) {
    var sort = NhentaiSort.values[int.parse(appdata.settings[39])];
    return NhentaiNetwork().getCategoryComics(path, i, sort);
  }

  @override
  Widget? get tailing {
    var sort = NhentaiSort.values[int.parse(appdata.settings[39])];
    Widget buildItem(String title, String value) {
      return RadioListTile<String>(
        title: Text(title),
        groupValue: sort.index.toString(),
        value: value,
        onChanged: (i){
          appdata.settings[39] = value;
          appdata.updateSettings();
          App.globalBack();
          refresh();
        },
      );
    }

    return Tooltip(
      message: "选择搜索模式".tl,
      child: IconButton(
        icon: const Icon(Icons.sort),
        onPressed: () {
          showDialog(context: App.globalContext!, builder: (context){
            return SimpleDialog(
                title: Text("选择漫画排序模式".tl),
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 400,),
                      buildItem("最新".tl, '0'),
                      buildItem("热门 | 今天".tl, '1'),
                      buildItem("热门 | 一周".tl, '2'),
                      buildItem("热门 | 本月".tl, '3'),
                      buildItem("热门 | 所有时间".tl, '4'),
                    ],
                  )
                ]
            );
          });
        },
      ),

    );
  }

  @override
  String? get tag => "Nhentai category $path";

  @override
  String get title => path.substring(1).replaceAll('/', ' : ').replaceAll('-', ' ');

  @override
  ComicType get type => ComicType.nhentai;

  @override
  bool get withScaffold => true;
}
