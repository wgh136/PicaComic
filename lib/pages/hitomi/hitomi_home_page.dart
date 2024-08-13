import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/components/components.dart';

class HitomiHomePageLogic extends StateController {
  bool loading = true;
  String? message;
  int currentPage = 1;
  ComicList? comics;
  List<HitomiComicBrief> hitomiComics = [];

  void get(String url) async {
    var res = await HiNetwork().getComics(url);
    if (res.error) {
      message = res.errorMessage!;
    } else {
      var parseRes = await parseIds(res.data);
      if(parseRes) {
        comics = res.data;
      }
    }
    loading = false;
    update();
  }

  void loadNextPage(String url) async {
    var res = await HiNetwork().loadNextPage(comics!);
    if (res.error) {
      showToast(message: res.errorMessage!);
    } else {
      var parseRes = await parseIds(comics!);
      if(parseRes) {
        update();
      } else {
        showToast(message: message ?? "Error");
      }
    }
  }

  Future<bool> parseIds(ComicList comics) async {
    var futures = <Future<Res<HitomiComicBrief>>>[];
    Future<bool> wait() async {
      var result = await Future.wait(futures);
      futures.clear();
      for (var r in result) {
        if(r.error) {
          message = r.errorMessage;
          return false;
        }
        hitomiComics.add(r.data);
      }
      return true;
    }
    for(var id in comics.comicIds) {
      if(futures.length >= 5) {
        var res = await wait();
        if(!res) return false;
      }
      futures.add(HiNetwork().getComicInfoBrief(id.toString()));
    }
    var res = await wait();
    if(!res) return false;
    comics.comicIds.clear();
    return true;
  }

  void refresh_() {
    loading = true;
    comics = null;
    message = null;
    currentPage = 1;
    update();
  }
}

class HitomiHomePageComics extends StatelessWidget {
  const HitomiHomePageComics(this.url, {Key? key}) : super(key: key);
  final String url;

  static void Function() refresh = () {};

  @override
  Widget build(BuildContext context) {
    return StateBuilder<HitomiHomePageLogic>(
        tag: url,
        init: HitomiHomePageLogic(),
        builder: (logic) {
          refresh = logic.refresh_;
          if (logic.loading) {
            logic.get(url);
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (logic.message != null) {
            return NetworkError(
              message: logic.message!,
              retry: () => logic.refresh_(),
              withAppbar: false,
            );
          } else {
            return CustomScrollView(
              slivers: [
                SliverGridComics(
                  comics: logic.hitomiComics,
                  sourceKey: "hitomi",
                  onLastItemBuild: () {
                    logic.loadNextPage(url);
                  },
                ),
                if (logic.comics!.toLoad < logic.comics!.total)
                  const SliverToBoxAdapter(
                    child: ListLoadingIndicator(),
                  )
              ],
            );
          }
        });
  }
}

class HitomiHomePage extends StatefulWidget {
  const HitomiHomePage({super.key});

  @override
  State<HitomiHomePage> createState() => _HitomiHomePageState();
}

class _HitomiHomePageState extends State<HitomiHomePage> {
  var type = "index";
  var lang = "-all";

  @override
  Widget build(BuildContext context) {
    var url = "https://ltn.hitomi.la/$type$lang.nozomi";
    return Column(
      children: [
        Material(
          textStyle: Theme.of(context).textTheme.headlineMedium,
          child: SizedBox(
            height: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(
                  width: 16,
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text("hitomi"),
                ),
                const Spacer(),
                Material(
                  child: Select(
                    values: [
                      "最新".tl,
                      "热门 | 今天".tl,
                      "热门 | 一周".tl,
                      "热门 | 本月".tl,
                      "热门 | 一年".tl
                    ],
                    initialValue: 0,
                    onChange: (i) => setState(() {
                      type = [
                        "index",
                        "popular/today",
                        "popular/week",
                        "popular/month",
                        "popular/year"
                      ][i];
                    }),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                Material(
                  child: Select(
                    width: 100,
                    values: const ["All", "中文", "日本語", "English"],
                    initialValue: 0,
                    onChange: (i) => setState(() {
                      lang = ["-all", "-chinese", "-japanese", "-english"][i];
                    }),
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: HitomiHomePageComics(
            url,
            key: Key(url),
          ),
        )
      ],
    );
  }
}
