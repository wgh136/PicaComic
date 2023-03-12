import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

class FavoritesPageLogic extends GetxController{
  var favorites = Favorites([], 1, 0);
  int page = 1;
  int pages = 0;
  var comics = <ComicItemBrief>[]; //加载指定页漫画使用的列表
  var controller = TextEditingController();
  bool isLoading = true;
  Future<void> get()async {
    if(favorites.comics.isEmpty){
      favorites = await network.getFavorites();
    }else{
      await network.loadMoreFavorites(favorites);
    }
  }
  void change(){
    isLoading = !isLoading;
    update();
  }
}



class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("收藏夹"),
        actions: [
          Tooltip(
            message: "更多",
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: (){
                showMenu(context: context,
                    position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width-60, 50, MediaQuery.of(context).size.width-60, 50),
                    items: [
                      PopupMenuItem(
                        child: const Text("浏览模式"),
                        onTap: (){
                          Future.delayed(const Duration(microseconds: 200),()=>changeMode(context));
                        },
                      ),
                      if(appdata.settings[11]=="1")
                      PopupMenuItem(
                        child: const Text("跳页"),
                        onTap: ()=>Future.delayed(const Duration(microseconds: 200),() async{
                          var s = await changePage(context);
                          if(s=="") return;
                          try{
                            var logic = Get.find<FavoritesPageLogic>();
                            var i = int.parse(s);
                            if(i<1||i>logic.pages){
                              showMessage(Get.context, "输入的页码不正确");
                            }else{
                              logic.page = i;
                              logic.change();
                            }
                          }
                          catch(e){
                            showMessage(Get.context, "输入的页码不正确");
                          }
                        }),
                      )
                    ]
                );
              },
            ),
          )
        ],
      ),
      body: GetBuilder<FavoritesPageLogic>(
        init: FavoritesPageLogic(),
          builder: (favoritesPageLogic){
            favoritesPageLogic.controller = TextEditingController();
            return appdata.settings[11]=="0"?buildComicList(favoritesPageLogic, context):buildComicListWithSelectedPage(favoritesPageLogic, context);
      }),
    );
  }

  Widget buildComicList(FavoritesPageLogic favoritesPageLogic, BuildContext context){
    if(favoritesPageLogic.isLoading) {
      favoritesPageLogic.get().then((t)=>favoritesPageLogic.change());
      return const Center(child: CircularProgressIndicator(),);
    }else if(favoritesPageLogic.favorites.loaded!=0){
      return RefreshIndicator(
        onRefresh: () async{
          favoritesPageLogic.favorites = Favorites([], 1, 0);
          await favoritesPageLogic.get();
          favoritesPageLogic.update();
        },
        child: CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: favoritesPageLogic.favorites.comics.length,
                      (context, i){
                    if(i == favoritesPageLogic.favorites.comics.length-1&&favoritesPageLogic.favorites.pages!=favoritesPageLogic.favorites.loaded){
                      network.loadMoreFavorites(favoritesPageLogic.favorites).then((t)=>favoritesPageLogic.update());
                    }
                    return ComicTile(favoritesPageLogic.favorites.comics[i]);
                  }
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            ),
            if(favoritesPageLogic.favorites.pages!=favoritesPageLogic.favorites.loaded&&favoritesPageLogic.favorites.pages!=1)
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 80,
                  child: const Center(
                    child: SizedBox(
                      width: 20,height: 20,
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
            SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
          ],
        ),
      );
    }else{
      return showNetworkError(context, ()=>favoritesPageLogic.change(), showBack: false);
    }
  }

  Widget buildComicListWithSelectedPage(FavoritesPageLogic favoritesPageLogic,BuildContext context){
    if(favoritesPageLogic.isLoading){
      network.getSelectedPageFavorites(favoritesPageLogic.page,favoritesPageLogic.comics).then((i){
        favoritesPageLogic.isLoading = false;
        favoritesPageLogic.pages = i;
        favoritesPageLogic.update();
      });
      return const Center(child: CircularProgressIndicator(),);
    }else {
      return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: favoritesPageLogic.comics.length,
                  (context, i)=>ComicTile(favoritesPageLogic.comics[i])
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: comicTileMaxWidth,
            childAspectRatio: comicTileAspectRatio,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 80,
            child: Row(
              children: [
                const SizedBox(width: 10,),
                FilledButton(
                    onPressed: (){
                      if(favoritesPageLogic.page==1||favoritesPageLogic.pages==0){
                        showMessage(context, "已经是第一页了");
                      }else{
                        favoritesPageLogic.page--;
                        favoritesPageLogic.change();
                      }
                    },
                    child: const Text("上一页")
                ),
                const Spacer(),
                Text("${favoritesPageLogic.page}/${favoritesPageLogic.pages}"),
                const Spacer(),
                FilledButton(
                    onPressed: (){
                      if(favoritesPageLogic.page==favoritesPageLogic.pages||favoritesPageLogic.pages==0){
                        showMessage(context, "已经是最后一页了");
                      }else{
                        favoritesPageLogic.page++;
                        favoritesPageLogic.change();
                      }
                    },
                    child: const Text("下一页")
                ),
                const SizedBox(width: 10,),
              ],
            ),
          ),
        ),

      ],
    );
    }
  }

  void changeMode(BuildContext context){
    showDialog(context: context, builder: (dialogContext)=>GetBuilder(
        init: RadioLogic(),
        builder: (logic)=>SimpleDialog(
          title: const Text("选择浏览方式"),
          children: [
            const SizedBox(width: 400,),
            ListTile(
              title: const Text("顺序浏览"),
              trailing: Radio(value: 0, groupValue: logic.value, onChanged: (i)=>logic.changeValue(i!)),
              onTap: ()=>logic.changeValue(0),
            ),
            ListTile(
              title: const Text("分页浏览"),
              trailing: Radio(value: 1, groupValue: logic.value, onChanged: (i)=>logic.changeValue(i!)),
              onTap: ()=>logic.changeValue(1),
            )
          ],
        )
    ));
  }

  Future<String> changePage(BuildContext context) async{
    var controller = TextEditingController();
    var logic = Get.find<FavoritesPageLogic>();
    String res = "";
    await showDialog(context: context, builder: (dialogContext)=>SimpleDialog(
      title: const Text("切换页面"),
      children: [
        const SizedBox(width: 400,),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          child: TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "页码",
              suffixText: "输入1-${logic.pages}之间的数字",
            ),
            controller: controller,
            onSubmitted: (s){
              res =  s;
              Get.back();
            },
          ),
        ),
        Center(child: FilledButton(
          child: const Text("提交"),
          onPressed: (){
            res = controller.text;
            Get.back();
          },
        ),)
      ],
    ));
    return res;
  }
}

class RadioLogic extends GetxController{
  var value = appdata.settings[11]=="0"?0:1;
  void changeValue(int i){
    value = i;
    appdata.settings[11] = i.toString();
    appdata.writeData();
    update();
    Get.back();
    Get.find<FavoritesPageLogic>().change();
  }
}
