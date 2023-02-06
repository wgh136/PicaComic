import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets.dart';

class HomePageLogic extends GetxController{
  bool isLoading = true;
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);
  final homePageLogic = Get.put(HomePageLogic());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePageLogic>(builder: (homePageLogic){
      if(homePageLogic.isLoading){
        network.getRandomComics().then((c) {
          for(var i in c){
            comics.add(i);
          }
          homePageLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else{
        return Material(
          child: RefreshIndicator(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    centerTitle: true,
                    title: const Text("探索"),
                    actions: [
                      Tooltip(
                        message: "搜索",
                        child: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: (){
                            Get.to(()=>SearchPage());
                          },
                        ),
                      ),
                    ],
                  ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: comics.length,
                            (context, i){
                          if(i == comics.length-1){
                            network.getRandomComics().then((c){
                              for(var i in c){
                                comics.add(i);
                              }
                              homePageLogic.update();
                            });
                          }
                          return ComicTile(comics[i]);
                        }
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600,
                      childAspectRatio: 5,
                    ),
                  ),
                ],
              ),
              onRefresh: () async {
                var c = await network.getRandomComics();
                var t = await network.getRandomComics();
                comics = c+t;
                homePageLogic.update();
              }
          ),
        );
      }
    });
  }
}
