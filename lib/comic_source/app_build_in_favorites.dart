import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/favorites.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/res.dart';

final picacgFavorites = FavoriteData(
    key: "picacg",
    title: "Picacg",
    multiFolder: false,
    loadComic: (i, [folder]) => PicacgNetwork().getFavorites(i, appdata.settings[30]=="1"),
    loadFolders: null
);

/// eh较为特殊, 写统一接口有点麻烦, 不要使用这个进行构建页面
final ehFavorites = FavoriteData(
    key: "ehentai",
    title: "ehentai",
    multiFolder: true,
    loadComic: (i, [folder]) => throw UnimplementedError(),
    loadFolders: null
);

final jmFavorites = FavoriteData(
    key: "jm",
    title: "禁漫天堂",
    multiFolder: true,
    loadComic: (i, [folder]) => JmNetwork().getFolderComicsWithPage(folder!, i),
    loadFolders: () => JmNetwork().getFolders(),
    deleteFolder: (id) => JmNetwork().deleteFolder(id),
    addFolder: (name) => JmNetwork().createFolder(name),
    allFavoritesId: "0"
);

final htFavorites = FavoriteData(
    key: "htmanga",
    title: "绅士漫画",
    multiFolder: true,
    loadComic: (i, [folder]) => HtmangaNetwork().getFavoriteFolderComics(folder!, i),
    loadFolders: () => HtmangaNetwork().getFolders(),
    allFavoritesId: "0",
    deleteFolder: (id) async{
      var res = await HtmangaNetwork().deleteFolder(id);
      return res ? const Res(true) : const Res(false, errorMessage: "Network Error");
    },
    addFolder: (name) async{
      var res = await HtmangaNetwork().createFolder(name);
      return res ? const Res(true) : const Res(false, errorMessage: "Network Error");
    }
);

final nhentaiFavorites = FavoriteData(
    key: "nhentai",
    title: "nhentai",
    multiFolder: false,
    loadComic: (i, [folder]) => NhentaiNetwork().getFavorites(i),
    loadFolders: null
);