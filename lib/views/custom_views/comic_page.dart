import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/normal_comic_tile.dart';

class CustomComicPage extends ComicPage<ComicInfoData>{
  const CustomComicPage({required this.sourceKey, required this.id, super.key});

  final String sourceKey;

  @override
  final String id;

  @override
  // TODO: implement actions
  Row? get actions => null;

  @override
  void continueRead(History history) {
    // TODO: implement continueRead
  }

  @override
  String get cover => data!.cover;

  @override
  // TODO: implement downloadButton
  FilledButton get downloadButton => FilledButton(onPressed: (){}, child: Text("下载".tl));

  @override
  EpsData? get eps => data!.chapters != null ? EpsData(data!.chapters!.values.toList(), (ep) {
    // TODO: implement onTap
  }) : null;

  @override
  String? get introduction => data!.description;

  ComicSource? get comicSource => ComicSource.find(sourceKey);

  @override
  Future<Res<ComicInfoData>> loadData(){
    if(comicSource == null)  throw "Comic Source Not Found";
    return comicSource!.loadComicInfo!(id);
  }

  @override
  Future<bool> loadFavorite(ComicInfoData data) async{
    // TODO: implement loadFavorite
    return false;
  }

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(onPressed: (){
    readWithKey(sourceKey, id, 1, 1, data!.title, {
      "eps": data!.chapters,
      "cover": data!.cover
    });
  }, child: Text("从头开始".tl));

  @override
  SliverGrid? recommendationBuilder(ComicInfoData data) {
    if(data.suggestions == null)  return null;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => NormalComicTile(
          name: data.suggestions![index].title,
          subTitle_: data.suggestions![index].subTitle,
          tags: data.suggestions![index].tags,
          coverPath: data.suggestions![index].cover,
          description_: data.suggestions![index].description,
          onTap: () => MainPage.to(() => CustomComicPage(
              sourceKey: sourceKey, id: data.suggestions![index].id)),
        ),
        childCount: data.suggestions!.length,
      ),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }

  @override
  String get source => comicSource!.name;

  @override
  String get tag => "$key comic page with id: $id";

  @override
  Map<String, List<String>>? get tags => data!.tags;

  @override
  void tapOnTags(String tag) {
    // TODO: implement tapOnTags
  }

  @override
  ThumbnailsData? get thumbnailsCreator {
    if(data!.thumbnails == null && data!.thumbnailLoader == null)  return null;

    return ThumbnailsData(data!.thumbnails??[],
        (page) => data!.thumbnailLoader?.call(id, page) ?? Future.value(const Res.error("")),
        data!.thumbnailMaxPage);
  }

  @override
  String? get title => data!.title;

  @override
  FavoriteItem toLocalFavoriteItem() {
    // TODO: implement toLocalFavoriteItem
    throw UnimplementedError();
  }

  @override
  Card? get uploaderInfo => null;

}