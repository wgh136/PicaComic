import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';

class JmComicsPage extends StatefulWidget {
  const JmComicsPage(this.title, this.id, {super.key});

  final String title;

  final String id;

  @override
  State<JmComicsPage> createState() => _JmComicsPageState();
}

class _JmComicsPageState extends State<JmComicsPage> {
  bool loading = true;

  List<JmComicBrief>? list;

  int loaded = 0;

  int? max;

  String? message;

  void load() async {
    var res = await JmNetwork().getComicsPage(widget.id, loaded + 1);

    if (res.error) {
      if (list == null) {
        setState(() {
          loading = false;
          message = res.errorMessage;
        });
      }
    } else {
      loaded++;
      var (comics, maxPage) = res.data;
      list ??= [];
      setState(() {
        list!.addAll(comics);
        max ??= maxPage;
        loading = false;
      });
    }
  }

  void retry() {
    setState(() {
      message = null;
      list = null;
      loaded = 0;
      max = null;
      loading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      load();
      return showLoading(context);
    } else if (list != null) {
      return CustomScrollView(
        slivers: [
          CustomSliverAppbar(
            title: Text(widget.title),
            centerTitle: true,
          ),
          SliverGrid(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == list!.length - 1 && loaded != max) {
                load();
              }
              return JmComicTile(list![index]);
            }, childCount: list!.length),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: App.comicTileMaxWidth,
              childAspectRatio: App.comicTileAspectRatio,
            ),
          ),
          if (max != loaded)
            const SliverToBoxAdapter(
              child: ListLoadingIndicator(),
            )
        ],
      );
    } else {
      return showNetworkError(message!, retry, context);
    }
  }
}
