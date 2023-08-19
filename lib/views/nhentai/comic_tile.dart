import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';

import '../main_page.dart';

class NhentaiComicTile extends ComicTile{
  final NhentaiComicBrief comic;

  const NhentaiComicTile(this.comic, {super.key});

  @override
  String get description => "ID: ${comic.id}";

  @override
  void favorite() {
    // TODO: implement favorite
  }

  @override
  Widget get image => CachedNetworkImage(
    imageUrl: comic.cover,
    fit: BoxFit.cover,
    placeholder: (context, s) => ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
    errorWidget: (context, url, error) => const Icon(Icons.error),
    height: double.infinity,
    filterQuality: FilterQuality.medium,
  );

  @override
  void onTap_() {
    MainPage.to(() => NhentaiComicPage(comic.id));
  }

  @override
  String get subTitle => "";

  @override
  String get title => comic.title;

  @override
  int get maxLines => 4;
}