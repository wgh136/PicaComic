import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

import '../network/models.dart';

class HomePageLogic extends GetxController{
  bool isLoading = true;
  var comics = <ComicItemBrief>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePageLogic>(
      init: HomePageLogic(),
        builder: (homePageLogic){
      if(homePageLogic.isLoading){
        network.getRandomComics().then((c) {
          for(var i in c){
            homePageLogic.comics.add(i);
          }
          homePageLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(homePageLogic.comics.isNotEmpty){
        return Material(
          child: RefreshIndicator(
              child: CustomScrollView(
                slivers: [
                  if(MediaQuery.of(context).size.width<changePoint)
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
                  if(MediaQuery.of(context).size.width>changePoint)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 180,
                        child: const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(padding: EdgeInsets.fromLTRB(15, 0, 0, 30),child: Text("探索",style: TextStyle(fontSize: 28),),),
                        ),
                      ),
                    ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: homePageLogic.comics.length,
                            (context, i){
                          if(i == homePageLogic.comics.length-1){
                            network.getRandomComics().then((c){
                              for(var i in c){
                                homePageLogic.comics.add(i);
                              }
                              homePageLogic.update();
                            });
                          }
                          return ComicTile(homePageLogic.comics[i]);
                        }
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600,
                      childAspectRatio: 3.5,
                    ),
                  ),
                ],
              ),
              onRefresh: () async {
                var c = await network.getRandomComics();
                var t = await network.getRandomComics();
                homePageLogic.comics = c+t;
                homePageLogic.update();
              }
          ),
        );
      }else{
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height/2-80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.error_outline,size:60,),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2+20,
              left: MediaQuery.of(context).size.width/2-50,
              child: SizedBox(
                width: 100,
                height: 40,
                child: FilledButton(
                  onPressed: (){
                    homePageLogic.change();
                  },
                  child: const Text("重试"),
                ),
              ),
              ),
          ],
        );
      }
    });
  }
}
