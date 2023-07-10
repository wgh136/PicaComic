import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

import '../widgets/comic_tile.dart';

class HiComicTile extends ComicTile {
  final HitomiComicBrief comic;
  const HiComicTile(this.comic, {super.key});

  @override
  void favorite() {
    showMessage(Get.context, "无法添加收藏");
  }

  @override
  String get description => (){
    var description = "${comic.type}    ";
    description += comic.lang;
    return description;
  }.call();

  @override
  Widget get image => CachedNetworkImage(
    httpHeaders: const {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
      "Referer": "https://hitomi.la/"
    },
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    imageUrl: comic.cover,
    fit: BoxFit.cover,
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void onTap_() {
    Get.to(() => HitomiComicPage(comic), preventDuplicates: false);
  }

  @override
  String get subTitle => comic.artist;

  @override
  String get title => comic.name;

}

class ComicDescription extends StatelessWidget {
  const ComicDescription({super.key,
    required this.title,
    required this.user,
    required this.subDescription,
  });

  final String title;
  final String user;
  final String subDescription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
            maxLines: 1,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  subDescription,
                  style: const TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HitomiComicTileDynamicLoading extends StatefulWidget {
  const HitomiComicTileDynamicLoading(this.id, {Key? key}) : super(key: key);
  final int id;

  @override
  State<HitomiComicTileDynamicLoading> createState() => _HitomiComicTileDynamicLoadingState();
}

class _HitomiComicTileDynamicLoadingState extends State<HitomiComicTileDynamicLoading> {
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
    for(var cachedComic in cache){
      var id = RegExp(r"\d+(?=\.html)").firstMatch(cachedComic.link)![0]!;
      if(id == widget.id.toString()){
        comic = cachedComic;
      }
    }
    if(comic == null) {
      HiNetwork().getComicInfoBrief(widget.id.toString()).then((c){
        if(c.error){
          showMessage(context, c.errorMessage!);
          return;
        }
        cache.add(c.data);
        if(onScreen) {
          setState(() {
            comic = c.data;
          });
        }
      });

      return buildLoadingWidget();
    }else{
      return HiComicTile(comic!);
    }
  }

  Widget buildLoadingWidget(){
    return Shimmer(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Container(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16)
        ),
        child: Row(
          children: [
            const SizedBox(width: 16,),
            Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(140)
                  ),
                  clipBehavior: Clip.antiAlias,
                )
            ),
            SizedBox.fromSize(size: const Size(16,5),),
            Expanded(
              flex: 8,
              child: Column(
                children: [
                  const SizedBox(height: 3,),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(140)
                    ),
                    height: 25,
                  ),
                  const SizedBox(height: 3,),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(140)
                    ),
                    height: 20,
                  ),
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Theme.of(context).colorScheme.tertiaryContainer.withAlpha(140)
                    ),
                    height: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16,),
          ],
        ),
      ),
    );
  }


}
