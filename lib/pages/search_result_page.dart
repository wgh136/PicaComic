import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/components/components.dart';

class _SearchPageComicList extends ComicsPage<BaseComic> {
  const _SearchPageComicList({
    super.key,
    required this.loader,
    required this.keyword,
    required this.options,
    required this.head,
    required this.sourceKey,
  });

  final SearchFunction loader;

  final String keyword;

  final List<String> options;

  @override
  final String sourceKey;

  @override
  final Widget head;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) async {
    return await loader(keyword, i, options);
  }

  @override
  String? get tag => "$sourceKey search page with $keyword";

  @override
  String? get title => null;
}

class SearchResultPage extends StatelessWidget {
  const SearchResultPage({
    super.key,
    required this.keyword,
    this.options = const [],
    required this.sourceKey,
  });

  final String keyword;

  final List<String> options;

  final String sourceKey;

  @override
  Widget build(BuildContext context) {
    var comicSource = ComicSource.find(sourceKey)!;
    var options = this.options;
    if (comicSource.searchPageData?.searchOptions != null) {
      var searchOptions = comicSource.searchPageData!.searchOptions!;
      if(searchOptions.length != options.length) {
        options = searchOptions.map((e) => e.defaultValue).toList();
      }
    }
    if(comicSource.searchPageData?.overrideSearchResultBuilder != null) {
      return comicSource.searchPageData!.overrideSearchResultBuilder!(
        keyword,
        options,
      );
    } else {
      return _SearchResultPage(
        keyword: keyword,
        options: options,
        loader: comicSource.searchPageData!.loadPage!,
        sourceKey: sourceKey,
      );
    }
  }
}

class _SearchResultPage extends StatefulWidget {
  const _SearchResultPage({
    required this.keyword,
    required this.options,
    required this.loader,
    required this.sourceKey,
  });

  final String keyword;

  final SearchFunction loader;

  final List<String> options;

  final String sourceKey;

  @override
  State<_SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<_SearchResultPage> {
  var controller = TextEditingController();
  bool _showFab = true;
  late String keyword = widget.keyword;

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      floatingActionButton: _showFab
          ? FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () {
                var s = controller.text;
                setState(() {
                  keyword = s;
                });
              },
            )
          : null,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final ScrollDirection direction = notification.direction;
          var showFab = _showFab;
          if (direction == ScrollDirection.reverse) {
            _showFab = false;
          } else if (direction == ScrollDirection.forward) {
            _showFab = true;
          }
          if (_showFab == showFab) return true;
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
                onSearch: (s) {
                  if (s == keyword) return;
                  setState(() {
                    keyword = s;
                  });
                },
                controller: controller,
              ),
            ),
          ),
          options: widget.options,
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
