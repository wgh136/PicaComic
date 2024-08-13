import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/base_image_provider.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';

class ImageFavoritesPage extends StatefulWidget {
  const ImageFavoritesPage({super.key});

  @override
  State<ImageFavoritesPage> createState() => _ImageFavoritesPageState();
}

class _ImageFavoritesPageState extends State<ImageFavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return StateBuilder(
      tag: "image_favorites_page",
      init: SimpleController(),
      builder: (controller){
        if(UiMode.m1(context)){
          return Scaffold(
            appBar: AppBar(
              title: Text("图片收藏".tl),
            ),
            body: buildPage(),
          );
        } else {
          return Material(
            child: Column(
              children: [
                Appbar(
                  title: Text("图片收藏".tl),
                ),
                Expanded(
                  child: buildPage(),
                )
              ],
            ),
          );
        }
      },
    );
  }

  Widget buildPage(){
    var images = ImageFavoriteManager.getAll();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithComics(true, appdata.settings[74]),
      itemCount: images.length,
      itemBuilder: (context, index){
        return FavoriteImageTile(images[index]);
      },
    );
  }
}

class FavoriteImageTile extends StatelessWidget {
  const FavoriteImageTile(this.image, {super.key});

  final ImageFavorite image;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        child: Stack(
          children: [
            Positioned.fill(child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8)),
                clipBehavior: Clip.antiAlias,
                child: Image(image: _ImageProvider(image),))),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.5),
                          ]),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      image.title.replaceAll("\n", ""),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongTap,
                  onSecondaryTapDown: onSecondaryTap,
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox.expand(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void onTap(){
    var type = image.id.split("-")[0];
    // TODO: read
    /*
    readWithKey(type, image.id.replaceFirst("$type-", ""),
        image.ep, image.page, image.title, image.otherInfo);*/
  }

  void onLongTap(){
    showConfirmDialog(App.globalContext!, "确认删除".tl, "要删除这个图片吗".tl, delete);
  }

  void delete(){
    ImageFavoriteManager.delete(image);
    showToast(message: "删除成功".tl);
    StateController.findOrNull(tag: "image_favorites_page")?.update();
  }

  void onSecondaryTap(TapDownDetails details){
    showDesktopMenu(App.globalContext!, details.globalPosition, [
      DesktopMenuEntry(text: "查看".tl, onClick: onTap),
      DesktopMenuEntry(text: "删除".tl, onClick: delete),
    ]);
  }
}

class _ImageProvider extends BaseImageProvider<_ImageProvider>{
  _ImageProvider(this.image);
  
  final ImageFavorite image;
  
  @override
  String get key => image.id + image.ep.toString() + image.page.toString();

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    if(File(image.imagePath).existsSync()){
      return await File("${App.dataPath}/images/${image.imagePath}").readAsBytes();
    } else {
      var type = image.id.split("-")[0];
      Stream<DownloadProgress> stream;
      switch(type){
        case "ehentai":
          stream = ImageManager().getEhImageNew(Gallery.fromJson(image.otherInfo["gallery"]), image.page);
        case "jm":
          stream = ImageManager().getJmImage(image.otherInfo["url"], null, epsId: image.otherInfo["epsId"], scrambleId: "220980", bookId: image.otherInfo["bookId"]);
        case "hitomi":
          stream = ImageManager().getHitomiImage(HitomiFile.fromMap(image.otherInfo["hitomi"][image.page-1]), image.otherInfo["galleryId"]);
        default:
          stream = ImageManager().getImage(image.otherInfo["url"]);
      }
      DownloadProgress? finishProgress;
      await for (var progress in stream) {
        if (progress.currentBytes == progress.expectedBytes) {
          finishProgress = progress;
        }
        chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: progress.currentBytes,
            expectedTotalBytes: progress.expectedBytes)
        );
      }
      var file = finishProgress!.getFile();
      var data = await file.readAsBytes();
      var file2 = File("${App.dataPath}/images/${image.imagePath}");
      if(!file2.existsSync()){
        await file2.create(recursive: true);
      }
      await file2.writeAsBytes(data);
      return data;
    }
  }

  @override
  Future<_ImageProvider> obtainKey(ImageConfiguration configuration) async{
    return this;
  }
}