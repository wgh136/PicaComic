import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/views/ht_views/ht_comic_page.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:get/get.dart';

class HtComicTile extends ComicTile{
  const HtComicTile({required this.comic, super.key});

  final HtComicBrief comic;

  @override
  String get description => comic.time;

  @override
  void favorite() {
    // TODO: implement favorite
  }

  @override
  Widget get image => CachedNetworkImage(
    imageUrl: comic.image,
    fit: BoxFit.cover,
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void onTap_() => Get.to(() => HtComicPage(comic), preventDuplicates: false);

  @override
  String get subTitle => "${comic.pages} Pages";

  @override
  String get title => comic.name;

}