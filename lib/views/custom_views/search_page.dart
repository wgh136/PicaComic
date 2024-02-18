import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/views/custom_views/comic_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';

import '../../foundation/app.dart';
import '../../network/res.dart';
import '../widgets/normal_comic_tile.dart';
import '../widgets/search.dart';

class _SearchPageComicList extends ComicsPage<BaseComic>{
  const _SearchPageComicList({super.key, required this.loader, required this.keyword,
    required this.options, required this.head, required this.sourceKey});

  final SearchFunction loader;

  final String keyword;

  final List<String> options;

  final String sourceKey;

  @override
  final Widget head;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) async{
    return await loader(keyword, i, options);
  }

  @override
  String? get tag => "custom search page with $keyword and $options";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.other;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;

  @override
  bool get showBackWhenLoading => false;

  @override
  Widget buildItem(BuildContext context, BaseComic item) {
    return NormalComicTile(
        description_: item.description,
        coverPath: item.cover,
        name: item.title,
        subTitle_: item.subTitle,
        tags: item.tags,
        onTap: () => MainPage.to(() => CustomComicPage(sourceKey: sourceKey, id: item.id)));
  }
}

class CustomSearchPage extends StatefulWidget {
  const CustomSearchPage({required this.keyword, required this.options,
    required this.loader, required this.sourceKey, super.key});

  final String keyword;

  final SearchFunction loader;

  final List<String> options;

  final String sourceKey;

  @override
  State<CustomSearchPage> createState() => _CustomSearchPageState();
}

class _CustomSearchPageState extends State<CustomSearchPage> {
  var controller = TextEditingController();
  bool _showFab = true;
  late String keyword = widget.keyword;

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      floatingActionButton: _showFab?FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: (){
          var s = controller.text;
          if(s=="") return;
          setState(() {
            keyword = s;
          });
        },
      ):null,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final ScrollDirection direction = notification.direction;
          var showFab = _showFab;
          if (direction == ScrollDirection.reverse) {
            _showFab = false;
          } else if (direction == ScrollDirection.forward) {
            _showFab = true;
          }
          if(_showFab == showFab) return true;
          setState(() {});
          return true;
        },
        child: _SearchPageComicList(
          keyword: keyword,
          loader: widget.loader,
          sourceKey: widget.sourceKey,
          key: Key(keyword + widget.options.toString()),
          head: SliverPersistentHeader(
            floating: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 0,
              child: FloatingSearchBar(
                onSearch:(s){
                  App.back(context);
                  if(s=="") return;
                  setState(() {
                    keyword = s;
                  });
                },
                target: ComicType.other,
                controller: controller,),
            ),
          ),
          options: widget.options,
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
