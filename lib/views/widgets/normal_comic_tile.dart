import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';

class NormalComicTile extends ComicTile {
  const NormalComicTile(
      {required this.description_,
      required this.coverPath,
      required this.name,
      required this.subTitle_,
      required this.onTap,
      this.onLongTap,
      super.key});
  final String description_;
  final String coverPath;
  final void Function() onTap;
  final String subTitle_;
  final String name;
  final void Function()? onLongTap;

  @override
  String get description => description_;

  @override
  void favorite() {}

  @override
  void onLongTap_() => onLongTap!=null?onLongTap!.call():null;

  @override
  Widget get image => CachedNetworkImage(
        imageUrl: coverPath,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) => const Icon(Icons.error),
        height: double.infinity,
        progressIndicatorBuilder: (context, s, p) =>
            ColoredBox(color: Theme.of(context).colorScheme.surfaceVariant),
      );

  @override
  void onTap_() => onTap();

  @override
  String get subTitle => subTitle_;

  @override
  String get title => name;
}
