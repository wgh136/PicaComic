import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets.dart';
import 'base.dart';

class SearchPageLogic extends GetxController{
  var searchResult = SearchResult("", "", [], 1, 0);
  bool isLoading = false;

  void change(){
    isLoading = !isLoading;
    update();
  }
}

class SearchPage extends StatelessWidget {
  final SearchPageLogic searchPageLogic = Get.put(SearchPageLogic());

  SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 10)),
              SliverPersistentHeader(
                floating: true,
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 0,
                  child: FloatingSearchBar(supportingText: '搜索',trailingIcon: const Icon(Icons.search_rounded),f:(s){
                    if(s=="") return;
                    searchPageLogic.change();
                    network.searchNew(s, "dd").then((t){
                      searchPageLogic.searchResult = t;
                      searchPageLogic.change();
                    });
                  },),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 5)),
              GetBuilder<SearchPageLogic>(builder: (searchPageLogic){
                if(searchPageLogic.isLoading){
                  return SliverToBoxAdapter(
                    child: SizedBox.fromSize(
                      size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),),
                  );
                }else{
                  if(searchPageLogic.searchResult.comics.isNotEmpty||searchPageLogic.searchResult.keyWord==""){
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                          childCount: searchPageLogic.searchResult.comics.length,
                              (context, i){
                            if(i == searchPageLogic.searchResult.comics.length-1){
                              network.loadMoreSearch(searchPageLogic.searchResult).then((c){
                                searchPageLogic.update();
                              });
                            }
                            return ComicTile(searchPageLogic.searchResult.comics[i]);
                          }
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 600,
                        childAspectRatio: 5,
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
            ],
          ),
        )
    );
  }
}

class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailingIcon,
    required this.supportingText,
    required this.f,
  }) : super(key: key);

  final double height;
  double get effectiveHeight {
    return max(height, 53);
  }
  final Widget? trailingIcon;
  final void Function(String) f;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 720),
        padding: const EdgeInsets.only(top: 5),
        width: double.infinity,
        height: effectiveHeight,
        child: Material(
          elevation: 0,
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Tooltip(
                message: "返回",
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (){
                    Get.back();
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextField(
                    autofocus: true,
                    cursorColor: colorScheme.primary,
                    style: textTheme.bodyLarge,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      hintText: supportingText,
                      hintStyle: textTheme.bodyLarge?.apply(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: f,
                  ),
                ),
              ),
              if (trailingIcon != null) trailingIcon!,
            ]),
          ),
        ),
      ),
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