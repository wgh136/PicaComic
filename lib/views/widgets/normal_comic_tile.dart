import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/views/widgets/animated_image.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';

class NormalComicTile extends ComicTile {
  const NormalComicTile(
      {required this.description_,
      required this.coverPath,
      required this.name,
      required this.subTitle_,
      required this.onTap,
      this.onLongTap,
      this.badgeName,
      this.headers = const {},
      super.key});
  final String description_;
  final String coverPath;
  final void Function() onTap;
  final String subTitle_;
  final String name;
  final void Function()? onLongTap;
  final String? badgeName;
  final Map<String, String> headers;

  @override
  String get description => description_;

  @override
  void onLongTap_() => onLongTap?.call();

  @override
  String? get badge => badgeName;

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          coverPath,
          headers: headers
        ),
        fit: BoxFit.cover,
    width: double.infinity,
        height: double.infinity,
      );

  @override
  void onTap_() => onTap();

  @override
  String get subTitle => subTitle_;

  @override
  String get title => name;
}
