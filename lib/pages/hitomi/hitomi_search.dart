import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import '../../foundation/app.dart';
import '../../network/res.dart';

class SearchPageComicList extends StatefulWidget {
  const SearchPageComicList(
      {super.key, required this.keyword, required this.head});

  final String keyword;

  final Widget head;

  @override
  State<SearchPageComicList> createState() => _SearchPageComicListState();
}

class _SearchPageComicListState
    extends LoadingState<SearchPageComicList, List<int>> {
  @override
  Widget buildContent(BuildContext context, List<int> data) {
    return SmoothCustomScrollView(
      slivers: [
        widget.head,
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => HitomiComicTileDynamicLoading(data[index]),
            childCount: data.length,
          ),
          gridDelegate: SliverGridDelegateWithComics(),
        ),
      ],
    );
  }

  @override
  Future<Res<List<int>>> loadData() {
    return HiNetwork().search(widget.keyword);
  }
}

class HitomiSearchPage extends StatefulWidget {
  const HitomiSearchPage(this.keyword, {Key? key}) : super(key: key);
  final String keyword;

  @override
  State<HitomiSearchPage> createState() => _HitomiSearchPageState();
}

class _HitomiSearchPageState extends State<HitomiSearchPage> {
  late String keyword;
  var controller = TextEditingController();

  @override
  void initState() {
    keyword = widget.keyword;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      body: SearchPageComicList(
        keyword: keyword,
        key: Key(keyword),
        head: SliverPersistentHeader(
          floating: true,
          delegate: _SliverAppBarDelegate(
            minHeight: 60,
            maxHeight: 0,
            child: FloatingSearchBar(
              onSearch: (s) {
                App.back(context);
                if (s == "") return;
                setState(() {
                  keyword = s;
                });
              },
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

class HitomiComicTileDynamicLoading extends StatefulWidget {
  const HitomiComicTileDynamicLoading(this.id,
      {Key? key, this.addonMenuOptions})
      : super(key: key);
  final int id;

  final List<ComicTileMenuOption>? addonMenuOptions;

  @override
  State<HitomiComicTileDynamicLoading> createState() =>
      _HitomiComicTileDynamicLoadingState();
}

class _HitomiComicTileDynamicLoadingState
    extends State<HitomiComicTileDynamicLoading> {
  HitomiComicBrief? comic;
  bool onScreen = true;

  static List<HitomiComicBrief> cache = [];

  @override
  void dispose() {
    onScreen = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (var cachedComic in cache) {
      var id = RegExp(r"\d+(?=\.html)").firstMatch(cachedComic.link)![0]!;
      if (id == widget.id.toString()) {
        comic = cachedComic;
      }
    }
    if (comic == null) {
      HiNetwork().getComicInfoBrief(widget.id.toString()).then((c) {
        if (c.error) {
          showToast(message: c.errorMessage!);
          return;
        }
        cache.add(c.data);
        if (onScreen) {
          setState(() {
            comic = c.data;
          });
        }
      });

      return buildLoadingWidget();
    } else {
      return buildComicTile(context, comic!, 'hitomi');
    }
  }

  Widget buildPlaceHolder() {
    return const ComicTilePlaceholder();
  }

  Widget buildLoadingWidget() {
    return Shimmer(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: buildPlaceHolder(),
    );
  }
}
