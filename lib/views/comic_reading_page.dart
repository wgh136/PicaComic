import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/views/base.dart';

class ComicReadingPageLogic extends GetxController{
  ComicReadingPageLogic(this.order);
  bool isLoading = true;
  int index = 1;
  int order;
  var urls = <String>[];
  var epsWidgets = <Widget>[
    const ListTile(
      leading: Icon(Icons.library_books),
      title: Text("章节"),
    ),
  ];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ComicReadingPage extends StatelessWidget {
  final String comicId;
  final List<String> eps;
  ComicReadingPage(this.comicId,order,this.eps,{Key? key}) : super(key: key){
    final comicReadingPageLogic = Get.put(ComicReadingPageLogic(order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ComicReadingPageLogic>(builder: (comicReadingPageLogic){
        if(comicReadingPageLogic.isLoading){
          for(int i = 1;i < eps.length;i++){
            comicReadingPageLogic.epsWidgets.add(ListTile(
              title: Text(eps[i]),
              onTap: (){
                if(i != comicReadingPageLogic.order) {
                  comicReadingPageLogic.order = i;
                  comicReadingPageLogic.urls = [];
                  comicReadingPageLogic.change();
                }
                Navigator.pop(context);
              },
            ));
          }
          network.getComicContent(comicId, comicReadingPageLogic.order).then((l){
            comicReadingPageLogic.urls = l;
            comicReadingPageLogic.change();
          });
          return const DecoratedBox(decoration: BoxDecoration(color: Colors.black),child: Center(
            child: CircularProgressIndicator(),
          ),);
        }else{
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                bottom: 0,
                right: 0,
                child: PhotoViewGallery.builder(
                  itemCount: comicReadingPageLogic.urls.length,
                  builder: (BuildContext context, int index){
                    if(index!=comicReadingPageLogic.urls.length-1) {
                      precacheImage(NetworkImage(comicReadingPageLogic.urls[index+1]), context);
                    }
                    return PhotoViewGalleryPageOptions(
                      minScale: PhotoViewComputedScale.contained,
                      imageProvider: NetworkImage(comicReadingPageLogic.urls[index]),
                      initialScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(tag: "$index/${comicReadingPageLogic.urls.length}"),
                    );
                  },
                  loadingBuilder: (context, event) => DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: Center(
                      child: SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          value: event == null
                              ? 0
                              : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                        ),
                      ),
                    ),
                  ),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  onPageChanged: (i){
                    comicReadingPageLogic.index = i+1;
                    comicReadingPageLogic.update();
                  },
                ),
              ),
              Positioned(
                bottom: 13,
                left: 25,
                child: Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: const TextStyle(color: Colors.white),),
              ),
              Positioned(
                  bottom: 0,
                  right: 25,
                  child: Tooltip(
                    message: "章节",
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: (){
                        showModalBottomSheet(
                            context: context,
                            builder: (context){
                              return ListView(
                                children: comicReadingPageLogic.epsWidgets,
                              );
                            }
                        );
                      },
                    ),
                  )
              )
            ],
          );
        }
      }),
    );
  }
}
