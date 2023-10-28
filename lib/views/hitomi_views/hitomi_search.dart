import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import '../../foundation/app.dart';
import '../../network/res.dart';
import '../page_template/comics_page.dart';
import '../widgets/search.dart';

class PageData{
  List<int>? comics;
}

class SearchPageComicsList extends ComicsPage<int>{
  final String keyword;
  final Widget? head_;
  final data = PageData();
  SearchPageComicsList(this.keyword, {this.head_, super.key});

  @override
  Future<Res<List<int>>> getComics(int i) async{
    if(data.comics == null){
      var res = await HiNetwork().search(keyword);
      if(res.error){
        return Res(null, errorMessage: res.errorMessage);
      }else{
        data.comics = res.data;
      }
    }
    return Res(data.comics!.sublist((i-1)*20, i*20>data.comics!.length?null:i*20), subData: (data.comics!.length/20).ceil());
  }

  @override
  String? get tag => "Hitomi search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.hitomi;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class HitomiSearchPage extends StatefulWidget {
  const HitomiSearchPage(this.keyword, {Key? key}) : super(key: key);
  final String keyword;

  @override
  State<HitomiSearchPage> createState() => _HitomiSearchPageState();
}

class _HitomiSearchPageState extends State<HitomiSearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      body: SearchPageComicsList(
        keyword,
        key: Key(keyword),
        head_: SliverPersistentHeader(
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
              target: ComicType.hitomi,
              controller: controller,),
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