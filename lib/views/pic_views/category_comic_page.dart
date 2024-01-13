import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import '../../base.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class ModeRadioLogic1 extends StateController{
  int value = appdata.getSearchMode();
  void change(int i){
    value = i;
    appdata.setSearchMode(i);
    update();
  }
}

class CategoryComicPage extends ComicsPage<ComicItemBrief>{
  final String keyWord;
  final String cType;
  const CategoryComicPage(this.keyWord, {this.cType = "c", Key? key})
      : super(key: key);

  @override
  bool get centerTitle => true;

  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) async{
    return await network.getCategoryComics(keyWord, i, appdata.settings[1], cType);
  }

  @override
  bool get largeTitle => true;

  @override
  String? get tag => keyWord;

  @override
  String get title => keyWord;

  @override
  ComicType get type => ComicType.picacg;

  @override
  bool get withScaffold => true;

  @override
  Widget? get tailing => Tooltip(
    message: "选择漫画排序模式".tl,
    child: IconButton(
      icon: const Icon(Icons.manage_search_rounded),
      onPressed: (){
        showDialog(context: App.globalContext!, builder: (context){
          StateController.put(ModeRadioLogic1());
          return SimpleDialog(
              title: Text("选择漫画排序模式".tl),
              children: [StateBuilder<ModeRadioLogic1>(builder: (radioLogic){
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 400,),
                    ListTile(
                      trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        App.globalBack();
                      },),
                      title: Text("新到书".tl),
                      onTap: (){
                        radioLogic.change(0);
                        super.refresh();
                        App.globalBack();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        App.globalBack();
                      },),
                      title: Text("旧到新".tl),
                      onTap: (){
                        radioLogic.change(1);
                        super.refresh();
                        App.globalBack();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        App.globalBack();
                      },),
                      title: Text("最多喜欢".tl),
                      onTap: (){
                        radioLogic.change(2);
                        super.refresh();
                        App.globalBack();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        App.globalBack();
                      },),
                      title: Text("最多指名".tl),
                      onTap: (){
                        radioLogic.change(3);
                        super.refresh();
                        App.globalBack();
                      },
                    ),
                  ],
                );
              },),]
          );
        });
      },
    ),
  );
}