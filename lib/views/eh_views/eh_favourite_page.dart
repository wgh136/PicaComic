import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/net_fav_to_local.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import '../../foundation/app.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../main_page.dart';
import '../widgets/my_icons.dart';

class EhFavoritePage extends StatelessWidget {
  const EhFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    int num = 0;
    for(var folder in EhNetwork().folderNames){
      if(folder.contains('(') && folder.contains(')')) {
        num += (int.tryParse(folder
            .split('(')
            .last
            .split(')')
            .first) ?? 0);
      }
    }
    return CustomScrollView(
      slivers: [
        SliverGridViewWithFixedItemHeight(
          delegate: SliverChildBuilderDelegate(childCount: 11, (context, i) {
            if (i == 0) {
              var name = "全部".tl;
              if(num != 0){
                name += " ($num)";
              }
              return EhFolderTile(
                  name: name,
                  onTap: () => MainPage.to(
                      () => EhFavoritePageFolder(name: "全部".tl, folderId: -1)));
            } else {
              i--;
            }
            return EhFolderTile(
              name: EhNetwork().folderNames[i],
              onTap: () => MainPage.to(() => EhFavoritePageFolder(
                  name: EhNetwork().folderNames[i], folderId: i)),
            );
          }),
          maxCrossAxisExtent: 500,
          itemHeight: 64,
        ),
      ],
    );
  }
}

class PageData {
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}

class EhFavoritePageFolder extends ComicsPage<EhGalleryBrief> {
  EhFavoritePageFolder({required this.name, required this.folderId, super.key});

  final String name;

  final int folderId;

  final data = PageData();

  // 一次请求是50个
  @override
  Future<Res<List<EhGalleryBrief>>> getComics(int i) async {
    if (data.galleries == null) {
      Res<Galleries> res;
      if (folderId == -1) {
        res = await EhNetwork().getGalleries(
            "${EhNetwork().ehBaseUrl}/favorites.php?inline_set=dm_l",
            favoritePage: true);
      } else {
        res = await EhNetwork().getGalleries(
            "${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folderId&inline_set=dm_l",
            favoritePage: true);
      }
      if (res.error) {
        return Res(null, errorMessage: res.errorMessage);
      } else {
        data.galleries = res.data;
        data.comics[1] = [];
        data.comics[1]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
    }
    if (data.comics[i] != null) {
      return Res(data.comics[i]!);
    } else {
      while (data.comics[i] == null) {
        data.page++;
        if (!await EhNetwork().getNextPageGalleries(data.galleries!)) {
          return const Res(null, errorMessage: "网络错误");
        }
        data.comics[data.page] = [];
        data.comics[data.page]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
      return Res(data.comics[i]);
    }
  }

  @override
  String? get tag => "EhFavoritePageFolder $folderId";

  @override
  String get title => name;

  @override
  ComicType get type => ComicType.ehentai;

  @override
  bool get withScaffold => true;

  @override
  Widget? get tailing => Tooltip(
    message: "保存至本地".tl,
    child: IconButton(
      icon: const Icon(Icons.save),
      onPressed: (){
        startConvert((page) => getComics(page), null, App.globalContext!, name,
                (comic) => FavoriteItem.fromEhentai(comic), "ehentai", false, {"folderId": folderId});
      },
    ),
  );
}

class EhFolderTile extends StatelessWidget {
  const EhFolderTile({required this.name, required this.onTap, super.key});

  final String name;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Icon(
                  MyIcons.ehFolder,
                  size: 35,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Icon(Icons.arrow_right,
                  color: Theme.of(context).colorScheme.secondary)
            ],
          ),
        ),
      ),
    );
  }
}
