import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import '../widgets/search.dart';
import 'eh_widgets/eh_gallery_tile.dart';

class EhSearchPageLogic extends GetxController{
  Galleries? galleries;
  var controller = TextEditingController();
  bool isLoading = true;
  bool firstSearch = true;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void search() async{
    galleries = await ehNetwork.search(controller.text);
    change();
  }
}

class EhSearchPage extends StatelessWidget {
  final EhSearchPageLogic logic = Get.put(EhSearchPageLogic());
  final String keyword;
  EhSearchPage(this.keyword,{super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: (){
            var s = logic.controller.text;
            if(s=="") return;
            logic.change();
            logic.search();
          },
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 10)),
              SliverPersistentHeader(
                floating: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 0,
                  child: FloatingSearchBar(
                    supportingText: '搜索',
                    f:(s){
                      if(s=="") return;
                      logic.change();
                      logic.search();
                    },
                    controller: logic.controller,),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 5)),
              GetBuilder<EhSearchPageLogic>(builder: (searchPageLogic){
                if(searchPageLogic.isLoading){
                  if(searchPageLogic.firstSearch){
                    searchPageLogic.firstSearch = false;
                    searchPageLogic.controller.text = keyword;
                    searchPageLogic.search();
                  }
                  return SliverToBoxAdapter(
                    child: SizedBox.fromSize(
                      size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height-60),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),),
                  );
                }else{
                  if(searchPageLogic.galleries!=null){
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                          childCount: logic.galleries!.length,
                              (context, i){
                            if(i==logic.galleries!.length-1){
                              ehNetwork.getNextPageGalleries(logic.galleries!).then((v)=>logic.update());
                            }
                            return EhGalleryTile(logic.galleries![i]);
                          }
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: comicTileMaxWidth,
                        childAspectRatio: comicTileAspectRatio,
                      ),
                    );
                  }else{
                    return const SliverToBoxAdapter(
                      child: ListTile(
                        leading: Icon(Icons.error_outline),
                        title: Text("没有任何结果"),
                      ),
                    );
                  }
                }
              }),
              GetBuilder<EhSearchPageLogic>(builder: (searchPageLogic){
                if(logic.galleries!=null&&logic.galleries!.next!=null) {
                  return SliverToBoxAdapter(
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
                  );
                }else{
                  return const SliverToBoxAdapter(child: SizedBox(height: 1,),);
                }
              }),

              SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
            ],
          ),
        )
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate{
  _SliverAppBarDelegate({required this.child,required this.maxHeight,required this.minHeight});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child,);
  }

  @override
  double get maxExtent => minHeight;

  @override
  double get minExtent => max(maxHeight,minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent || minHeight != oldDelegate.minExtent;
  }

}