import 'package:pica_comic/comic_source/app_build_in_favorites.dart';

import '../network/base_comic.dart';
import '../network/res.dart';

class FavoriteData{
  final String key;

  final String title;

  final bool multiFolder;

  final Future<Res<List<BaseComic>>> Function(int page, [String? folder]) loadComic;

  /// key-id, value-name
  final Future<Res<Map<String, String>>> Function()? loadFolders;

  /// A value of null disables this feature
  final Future<Res<bool>> Function(String key)? deleteFolder;

  /// A value of null disables this feature
  final Future<Res<bool>> Function(String name)? addFolder;

  /// A value of null disables this feature
  final String? allFavoritesId;

  const FavoriteData({
    required this.key,
    required this.title,
    required this.multiFolder,
    required this.loadComic,
    this.loadFolders,
    this.deleteFolder,
    this.addFolder,
    this.allFavoritesId});
}

FavoriteData getFavoriteData(String key){
  switch(key){
    case "picacg":
      return picacgFavorites;
    case "ehentai":
      return ehFavorites;
    case "jm":
      return jmFavorites;
    case "htmanga":
      return htFavorites;
    case "nhentai":
      return nhentaiFavorites;
  }
  return loadFavoritesDataFromConfig(key);
}

FavoriteData loadFavoritesDataFromConfig(String key){
  // TODO
  throw UnimplementedError();
}