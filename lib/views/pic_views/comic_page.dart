import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/pic_views/comments_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/base.dart';
import '../../foundation/app.dart';
import '../../foundation/history.dart';
import '../main_page.dart';
import '../widgets/grid_view_delegate.dart';
import '../widgets/select_download_eps.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class PicacgComicPage extends ComicPage<ComicItem> {
  final ComicItemBrief comic;
  const PicacgComicPage(this.comic, {super.key});
  
  Widget get buildButtons => SegmentedButton<int>(
    segments: [
      ButtonSegment(
        icon: Icon((data!.isLiked) ? Icons.favorite : Icons.favorite_border,
          color: Theme.of(context).colorScheme.primary,),
        label: Text(data!.likes.toString()),
        value: 1,
      ),
      ButtonSegment(
        icon: !favorite ?
          Icon(Icons.bookmark_add_outlined, color: Theme.of(context).colorScheme.primary,) :
          Icon(Icons.bookmark_add, color: Theme.of(context).colorScheme.primary,),
        label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
        value: 2,
      ),
      ButtonSegment(
        icon: Icon(Icons.comment_outlined, color: Theme.of(context).colorScheme.primary,),
        label: Text(data!.comments.toString()),
        value: 3,
      ),
    ],
    onSelectionChanged: (set){
      void func1(){
        network.likeOrUnlikeComic(comic.id);
        data!.isLiked = !data!.isLiked;
        update();
      }

      void func2(){
        favoriteComic(FavoriteComicWidget(
          havePlatformFavorite: appdata.token != "",
          needLoadFolderData: false,
          folders: const {"Picacg": "Picacg"},
          initialFolder: data!.isFavourite?null:"Picacg",
          favoriteOnPlatform: data!.isFavourite,
          target: comic.id,
          setFavorite: (b){
            if(favorite != b){
              favorite = b;
              update();
            }
          },
          cancelPlatformFavorite: (){
            network.favouriteOrUnfavouriteComic(comic.id);
            data!.isFavourite = false;
            update();
          },
          selectFolderCallback: (name, p){
            if(p == 0){
              network.favouriteOrUnfavouriteComic(comic.id);
              data!.isFavourite = true;
              update();
            }else{
              showMessage(App.globalContext, "已添加至收藏夹:".tl + name);
              LocalFavoritesManager().addComic(
                  name, FavoriteItem.fromPicacg(comic));
            }
          },
        ));
      }

      switch(set.first){
        case 1: func1();break;
        case 2: func2();break;
        case 3: showComments(App.globalContext!, comic.id); break;
      }
    },
    selected: const {},
    emptySelectionAllowed: true,
  );

  @override
  Row get actions => Row(
        children: [
          Expanded(child: buildButtons,)
        ],
      );

  @override
  String get cover => getImageUrl(comic.path);

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () {
          downloadComic(data!, context, data!.eps);
        },
        child: (downloadManager.downloaded.contains(comic.id))
            ? Text("修改".tl)
            : Text("下载".tl),
      );

  @override
  EpsData? get eps => EpsData(data!.eps, (i) async{
        await addPicacgHistory(data!);
        App.globalTo(() =>
            ComicReadingPage.picacg(comic.id, i + 1, data!.eps, comic.title));
      });

  @override
  String? get introduction => data?.description;

  @override
  Future<Res<ComicItem>> loadData() => network.getComicInfo(comic.id);

  @override
  int? get pages => data?.pagesCount;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readPicacgComic(data!, data!.eps, false),
        child: Text("从头开始".tl),
      );

  @override
  void continueRead(History history) {
    readPicacgComic(data!, data!.eps, true);
  }

  @override
  SliverGrid recommendationBuilder(data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: data.recommendation.length, (context, i) {
          return PicComicTile(data.recommendation[i]);
        }),
        gridDelegate: const SliverGridDelegateWithComics(),
      );

  @override
  String get tag => "Picacg Comic Page ${comic.id}";

  @override
  Map<String, List<String>>? get tags => {
        "作者".tl: data!.author.toList(),
        "汉化".tl: data!.chineseTeam.toList(),
        "分类".tl: data!.categories,
        "标签".tl: data!.tags
      };

  @override
  void tapOnTags(String tag){
    if(data!.categories.contains(tag)){
      MainPage.to(() => CategoryComicPage(tag, categoryType: 1,));
    }else if(data!.author == tag){
      MainPage.to(() => CategoryComicPage(tag, categoryType: 3,));
    }else {
      MainPage.to(() => CategoryComicPage(tag, categoryType: 2,));
    }
  }

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => comic.title;

  @override
  Future<bool> loadFavorite(ComicItem data) async{
    return data.isFavourite || (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  Card? get uploaderInfo => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.inversePrimary,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                flex: 0,
                child: Avatar(
                  size: 50,
                  avatarUrl: data!.creator.avatarUrl,
                  frame: data!.creator.frameUrl,
                  couldBeShown: true,
                  name: data!.creator.name,
                  slogan: data!.creator.slogan,
                  level: data!.creator.level,
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data!.creator.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                          "${data!.time.substring(0, 10)} ${data!.time.substring(11, 19)}更新")
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  String get id => comic.id;

  @override
  String get source => "Picacg";

  @override
  FavoriteItem toLocalFavoriteItem() => FavoriteItem.fromPicacg(comic);
}

class ComicPageLogic extends StateController {
  bool isLoading = true;
  ComicItem? comicItem;
  bool showAppbarTitle = false;
  String? message;
  var tags = <Widget>[];
  var categories = <Widget>[];
  var recommendation = <ComicItemBrief>[];
  var controller = ScrollController();
  var eps = <Widget>[
    ListTile(
      leading: const Icon(Icons.library_books),
      title: Text("章节".tl),
    ),
  ];
  var epsStr = <String>[""];
  void change() {
    isLoading = !isLoading;
    update();
  }
}

void downloadComic(
    ComicItem comic, BuildContext context, List<String> eps) async {
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
      return;
    }
  }
  var downloaded = <int>[];
  if (DownloadManager().downloaded.contains(comic.id)) {
    var downloadedComic = await DownloadManager().getComicFromId(comic.id);
    downloaded.addAll(downloadedComic.downloadedEps);
  }
  if (UiMode.m1(App.globalContext!)) {
    showModalBottomSheet(
        context: App.globalContext!,
        builder: (context) {
          return SelectDownloadChapter(eps, (selectedEps) {
            downloadManager.addPicDownload(comic, selectedEps);
            App.globalBack();
            showMessage(context, "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        App.globalContext!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addPicDownload(comic, selectedEps);
          App.globalBack();
          showMessage(context, "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}