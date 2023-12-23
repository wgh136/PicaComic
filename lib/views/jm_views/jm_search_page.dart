import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/views/settings/jm_settings.dart';
import '../../foundation/app.dart';
import '../../network/res.dart';
import '../page_template/comics_page.dart';
import '../widgets/search.dart';

class SearchPageComicsList extends ComicsPage {
  final String keyword;
  final Widget? head_;
  final ComicsOrder order;
  const SearchPageComicsList(this.keyword, this.order, {this.head_, super.key});

  @override
  Future<Res<List>> getComics(int i) {
    return JmNetwork().searchNew(keyword, i, order);
  }

  @override
  String? get tag => "Jm search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class JmSearchPage extends StatefulWidget {
  final String keyword;
  final ComicsOrder order;
  const JmSearchPage(this.keyword, {this.order = ComicsOrder.latest, Key? key})
      : super(key: key);

  @override
  State<JmSearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<JmSearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();
  late ComicsOrder order;

  @override
  void initState() {
    order = widget.order;
    controller.text = keyword;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SearchPageComicsList(
        keyword,
        order,
        key: Key(keyword + order.name),
        head_: SliverPersistentHeader(
          floating: true,
          delegate: _SliverAppBarDelegate(
            minHeight: 60,
            maxHeight: 0,
            child: FloatingSearchBar(
              trailing: IconButton(
                icon: const Icon(Icons.arrow_drop_down_sharp),
                onPressed: () =>
                    setJmComicsOrder(context, search: true).then((b) {
                  if (!b) {
                    setState(() {
                      order = ComicsOrder.values[int.parse(appdata.settings[19])];
                    });
                  }
                }),
              ),
              onSearch: (s) {
                App.back(context);
                if (s == "") return;
                setState(() {
                  keyword = s;
                });
              },
              target: ComicType.jm,
              controller: controller,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(
      {required this.child, required this.maxHeight, required this.minHeight});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  double get maxExtent => minHeight;

  @override
  double get minExtent => max(maxHeight, minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent;
  }
}
