import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/views/hitomi_views/hi_widgets.dart';
import 'package:pica_comic/base.dart';
import '../widgets/list_loading.dart';
import '../widgets/search.dart';


class HitomiSearchPageLogic extends GetxController{
  var controller = TextEditingController();
  bool isLoading = true;
  bool firstSearch = true;
  List<HitomiComicBrief>? comics;
  String? message;
  int totalPages = 1;
  int loadedPages = 0;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void search() async{
    var res = await HiNetwork().search(controller.text, 1);
    if(res.error){
      message = res.errorMessage;
    }else{
      comics = res.data;
    }
    totalPages = res.subData??1;
    loadedPages++;
    change();
  }

  void loadNestPage() async{
    var res = await HiNetwork().search(controller.text, loadedPages+1);
    if(res.error){
      message = res.errorMessage;
    }else{
      comics!.addAll(res.data);
    }
    totalPages = res.subData??1;
    loadedPages++;
    update();
  }

  void refresh_(){
    comics = null;
    message = null;
    totalPages = 1;
    loadedPages = 0;
    change();
    search();
  }
}

class HitomiSearchPage extends StatelessWidget {
  final String keyword;
  const HitomiSearchPage(this.keyword,{super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: HitomiSearchPageLogic(),
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
                      controller: logic.controller,
                    ),
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

  Widget buildBody(HitomiSearchPageLogic logic, BuildContext context){
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
      if(logic.comics!=null){
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: logic.comics!.length,
                  (context, i){
                if(i==logic.comics!.length-1){
                  logic.loadNestPage();
                }
                return HiComicTile(logic.comics![i]);
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
            leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.secondary,),
            title: Text(logic.message??"未知错误"),
          ),
        );
      }
    }
  }

  Widget buildLoading(HitomiSearchPageLogic logic, BuildContext context){
    if(logic.comics!=null&&logic.loadedPages<logic.totalPages) {
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