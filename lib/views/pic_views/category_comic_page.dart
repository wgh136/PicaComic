import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import '../../base.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class ModeRadioLogic1 extends GetxController{
  int value = appdata.getSearchMode();
  void change(int i){
    value = i;
    appdata.setSearchMode(i);
    update();
  }
}

class CategoryComicPage extends ComicsPage<ComicItemBrief>{
  final String keyWord;
  final int categoryType;
  const CategoryComicPage(this.keyWord,{this.categoryType=2,Key? key}) : super(key: key);

  @override
  bool get centerTitle => true;

  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) async{
    if(categoryType == 1){
      return await network.getCategoryComics(keyWord, i, appdata.settings[1]);
    }else{
      return await network.search(keyWord, appdata.settings[1], i);
    }
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
        showDialog(context: Get.context!, builder: (context){
          Get.put(ModeRadioLogic1());
          return SimpleDialog(
              title: Text("选择漫画排序模式".tl),
              children: [GetBuilder<ModeRadioLogic1>(builder: (radioLogic){
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 400,),
                    ListTile(
                      trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        Get.back();
                      },),
                      title: Text("新到书".tl),
                      onTap: (){
                        radioLogic.change(0);
                        super.refresh();
                        Get.back();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        Get.back();
                      },),
                      title: Text("旧到新".tl),
                      onTap: (){
                        radioLogic.change(1);
                        super.refresh();
                        Get.back();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        Get.back();
                      },),
                      title: Text("最多喜欢".tl),
                      onTap: (){
                        radioLogic.change(2);
                        super.refresh();
                        Get.back();
                      },
                    ),
                    ListTile(
                      trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                        radioLogic.change(i!);
                        super.refresh();
                        Get.back();
                      },),
                      title: Text("最多指名".tl),
                      onTap: (){
                        radioLogic.change(3);
                        super.refresh();
                        Get.back();
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