import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import '../widgets/search.dart';

class JmSearchPageLogic extends GetxController{
  var controller = TextEditingController();
  bool isLoading = true;
  bool firstSearch = true;
  SearchRes? searchRes;
  String? message;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void search() async{
    var res = await jmNetwork.search(controller.text);
    if(!res.error){
      searchRes = res.data;
    }else{
      message = res.errorMessage;
    }
    change();
  }
}

class JmSearchPage extends StatelessWidget {
  final String keyword;
  const JmSearchPage(this.keyword,{super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: JmSearchPageLogic(),
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

                buildBody(logic, context),
                buildLoading(logic, context),

                SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
              ],
            ),
          )
      ),
    );
  }

  Widget buildBody(JmSearchPageLogic logic, BuildContext context){
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
      if(logic.searchRes!=null){
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: logic.searchRes!.comics.length,
                  (context, i){
                if(i==logic.searchRes!.comics.length-1){
                  jmNetwork.loadSearchNextPage(logic.searchRes!).then((v)=>logic.update());
                }
                return JmComicTile(logic.searchRes!.comics[i]);
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
            title: Text(logic.message!),
          ),
        );
      }
    }
  }

  Widget buildLoading(JmSearchPageLogic logic, BuildContext context){
    if(logic.searchRes!=null&&logic.searchRes!.loaded<logic.searchRes!.total) {
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