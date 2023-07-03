import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/search.dart';

class SearchPageComicsList extends ComicsPage<HtComicBrief>{
  final String keyword;
  final Widget? head_;
  const SearchPageComicsList(this.keyword, {this.head_, super.key});

  @override
  Future<Res<List<HtComicBrief>>> getComics(int i) {
    return HtmangaNetwork().search(keyword, i);
  }

  @override
  String? get tag => "Ht search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.htManga;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class HtSearchPage extends StatefulWidget {
  final String keyword;
  const HtSearchPage(this.keyword, {Key? key}) : super(key: key);

  @override
  State<HtSearchPage> createState() => _HtSearchPageState();
}

class _HtSearchPageState extends State<HtSearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();
  bool _showFab = true;

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
          setState(() {
            if (direction == ScrollDirection.reverse) {
              _showFab = false;
            } else if (direction == ScrollDirection.forward) {
              _showFab = true;
            }
          });
          return true;
        },
        child: SearchPageComicsList(
          keyword,
          key: Key(keyword),
          head_: SliverPersistentHeader(
            floating: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 0,
              child: FloatingSearchBar(
                supportingText: '搜索'.tr,
                f:(s){
                  if(s=="") return;
                  setState(() {
                    keyword = s;
                  });
                },
                controller: controller,),
            ),
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