import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import '../../base.dart';
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
  final int? fCats;
  final int? startPages;
  final int? endPages;
  final int? minStars;
  const SearchPageComicsList(this.keyword, this.data,
      {this.fCats, this.startPages, this.endPages, this.minStars, this.head_, super.key});

  @override
  Future<Res<List<EhGalleryBrief>>> getComics(int i) async{
    if(data.galleries == null){
      var res = await EhNetwork().search(keyword, fCats: fCats,
          startPages: startPages, endPages: endPages, minStars: minStars);
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
          data.page--;
          return const Res(null, errorMessage: "网络错误");
        }
        data.comics[data.page] = [];
        data.comics[data.page]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
      return Res(data.comics[i]);
    }
  }

  @override
  String? get tag => "Eh search $keyword";

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

  @override
  bool get showBackWhenLoading => true;
}

class EhSearchPage extends StatefulWidget {
  final String keyword;
  final int? fCats;
  final int? startPages;
  final int? endPages;
  final int? minStars;
  const EhSearchPage(this.keyword, {this.fCats, this.startPages, this.endPages
    , this.minStars, Key? key}) : super(key: key);

  @override
  State<EhSearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<EhSearchPage> {
  late String keyword;
  var controller = TextEditingController();
  var data = PageData();

  @override
  void initState() {
    keyword = widget.keyword;
    if(appdata.settings[69] != "0" && !keyword.contains("lang")){
      keyword += " language:${["", "chinese", "english", "japanese"][int.parse(appdata.settings[69])]}";
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      body: SearchPageComicsList(
        keyword,
        data,
        key: Key(keyword),
        fCats: widget.fCats,
        startPages: widget.startPages,
        endPages: widget.endPages,
        minStars: widget.minStars,
        head_: SliverPersistentHeader(
          floating: true,
          delegate: _SliverAppBarDelegate(
            minHeight: 60,
            maxHeight: 0,
            child: FloatingSearchBar(
              onSearch:(s){
                App.back(context);
                if(s=="") return;
                data = PageData();
                setState(() {
                  keyword = s;
                });
              },
              target: ComicType.ehentai,
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