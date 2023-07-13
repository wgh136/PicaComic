import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../widgets/my_icons.dart';


class EhFavoritePage extends StatelessWidget{
  const EhFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: 11,
                  (context, i){
                if(i == 0) {
                  return EhFolderTile(name: "全部", onTap: ()=>Get.to(()=>EhFavoritePageFolder(name: "全部", folderId: -1)));
                }else{
                  i--;
                }
                return EhFolderTile(name: EhNetwork().folderNames[i], onTap: ()=>Get.to(() => EhFavoritePageFolder(name: EhNetwork().folderNames[i], folderId: i)),);

              }
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            childAspectRatio: 5,
          ),
        ),
      ],
    );
  }
}

class PageData{
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}

class EhFavoritePageFolder extends ComicsPage{
  EhFavoritePageFolder({required this.name, required this.folderId, super.key});

  final String name;

  final int folderId;

  final data = PageData();

  @override
  Future<Res<List>> getComics(int i) async{
    if(data.galleries == null){
      Res<Galleries> res;
      if(folderId == -1){
        res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php", favoritePage: true);
      }else{
        res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folderId", favoritePage: true);
      }
      if(res.error){
        return Res(null, errorMessage: res.errorMessage);
      }else{
        data.galleries = res.data;
        data.comics[1] = [];
        data.comics[1]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
    }
    if(data.comics[i] != null){
      return Res(data.comics[i]!);
    }else{
      while(data.comics[i] == null){
        data.page++;
        if(! await EhNetwork().getNextPageGalleries(data.galleries!)){
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
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Icon(MyIcons.ehFolder, size: 35, color: Theme.of(context).colorScheme.secondary,),
              ),
              const SizedBox(width: 16,),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                ),
              ),
              Icon(Icons.arrow_right, color: Theme.of(context).colorScheme.secondary)
            ],
          ),
        ),
      ),
    );
  }
}
