import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/res.dart';
import '../page_template/comics_page.dart';
import '../widgets/search.dart';

class PageData{
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}

class SearchPageComicsList extends ComicsPage<EhGalleryBrief>{
  final String keyword;
  final Widget? head_;
  final PageData data;
  const SearchPageComicsList(this.keyword, this.data, {this.head_, super.key});

  @override
  Future<Res<List<EhGalleryBrief>>> getComics(int i) async{
    if(data.galleries == null){
      var res = await EhNetwork().search(keyword);
      if(res.error){
        return Res(null, errorMessage: res.errorMessage);
      }else{
        data.galleries = res.data;
        data.comics[1] = [];
        data.comics[1]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
    }
    if(data.comics[i] != null){
      return Res(data.comics[i]!);
    }else{
      while(data.comics[i] == null){
        data.page++;
        if(! await EhNetwork().getNextPageGalleries(data.galleries!)){
          return Res(null, errorMessage: "网络错误");
        }
        data.comics[data.page] = [];
        data.comics[data.page]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
      return Res(data.comics[i]);
    }
  }

  @override
  String? get tag => "Picacg search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.ehentai;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;
}

class EhSearchPage extends StatefulWidget {
  final String keyword;
  const EhSearchPage(this.keyword, {Key? key}) : super(key: key);

  @override
  State<EhSearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<EhSearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();
  bool _showFab = true;
  var data = PageData();

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      floatingActionButton: _showFab?FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: (){
          var s = controller.text;
          if(s=="") return;
          data = PageData();
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
          data,
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
                  data = PageData();
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