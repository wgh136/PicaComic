import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/search.dart';
import 'package:pica_comic/tools/translations.dart';

class _SearchPageComicsList extends ComicsPage<NhentaiComicBrief>{
  final String keyword;
  final Widget? head_;
  final NhentaiSort sort;
  const _SearchPageComicsList(this.keyword, this.sort, {this.head_, super.key});

  @override
  Future<Res<List<NhentaiComicBrief>>> getComics(int i){
    return NhentaiNetwork().search(keyword, i, sort);
  }

  @override
  String? get tag => "Nhentai search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.nhentai;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class NhentaiSearchPage extends StatefulWidget {
  final String keyword;
  final NhentaiSort sort;
  const NhentaiSearchPage(this.keyword, {Key? key, this.sort = NhentaiSort.recent}) : super(key: key);

  @override
  State<NhentaiSearchPage> createState() => _NhentaiSearchPageState();
}

class _NhentaiSearchPageState extends State<NhentaiSearchPage> {
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
        child: _SearchPageComicsList(
          keyword,widget.sort,
          key: Key(keyword),
          head_: SliverPersistentHeader(
            floating: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 0,
              child: FloatingSearchBar(
                supportingText: '搜索'.tl,
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