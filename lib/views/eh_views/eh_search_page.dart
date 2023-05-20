import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import '../../network/eh_network/eh_main_network.dart';
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
    galleries = await EhNetwork().search(controller.text);
    change();
  }
}

class EhSearchPage extends StatelessWidget {
  final String keyword;
  const EhSearchPage(this.keyword,{super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: EhSearchPageLogic(),
      tag: keyword,
      builder: (logic)=>Scaffold(
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
                      supportingText: '搜索'.tr,
                      f:(s){
                        if(s=="") return;
                        logic.change();
                        logic.search();
                      },
                      controller: logic.controller,),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 5)),

                buildBody(logic, context),
                buildLoading(logic, context),

                SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
              ],
            ),
          )
      ),
    );
  }

  Widget buildBody(EhSearchPageLogic logic, BuildContext context){
    if(logic.isLoading){
      if(logic.firstSearch){
        logic.firstSearch = false;
        logic.controller.text = keyword;
        logic.search();
      }
      return SliverToBoxAdapter(
        child: SizedBox.fromSize(
          size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height-60),
          child: const Center(
            child: CircularProgressIndicator(),
          ),),
      );
    }else{
      if(logic.galleries!=null){
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: logic.galleries!.length,
                  (context, i){
                if(i==logic.galleries!.length-1){
                  EhNetwork().getNextPageGalleries(logic.galleries!).then((v)=>logic.update());
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
        return SliverToBoxAdapter(
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: Text("没有任何结果".tr),
          ),
        );
      }
    }
  }

  Widget buildLoading(EhSearchPageLogic logic, BuildContext context){
    if(logic.galleries!=null&&logic.galleries!.next!=null) {
      return const SliverToBoxAdapter(
        child: ListLoadingIndicator(),
      );
    }else{
      return const SliverToBoxAdapter(child: SizedBox(height: 1,),);
    }
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