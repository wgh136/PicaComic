import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/widgets.dart';

class ComicReadingPageLogic extends GetxController{
  var controller = PageController(initialPage: 1);
  ComicReadingPageLogic(this.order);
  bool isLoading = true;
  int index = 1;
  int order;
  bool tools = false;
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
    Get.put(ComicReadingPageLogic(order));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<ComicReadingPageLogic>(builder: (comicReadingPageLogic){
        if(comicReadingPageLogic.isLoading){
          comicReadingPageLogic.index = 1;
          comicReadingPageLogic.controller = PageController(initialPage: 1);
          comicReadingPageLogic.tools = false;
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
                  itemCount: comicReadingPageLogic.urls.length+2,
                  pageController: comicReadingPageLogic.controller,
                  builder: (BuildContext context, int index){
                    if(index<comicReadingPageLogic.urls.length) {
                      precacheImage(NetworkImage(comicReadingPageLogic.urls[index]), context);
                    }
                    if(index!=0&&index!=comicReadingPageLogic.urls.length+1) {
                      return PhotoViewGalleryPageOptions(
                      minScale: PhotoViewComputedScale.contained*0.9,
                      imageProvider: NetworkImage(comicReadingPageLogic.urls[index-1]),
                      initialScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(tag: "$index/${comicReadingPageLogic.urls.length}"),
                      onTapUp: (context,detail,value){
                        if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx>MediaQuery.of(context).size.width*0.75&&comicReadingPageLogic.index!=comicReadingPageLogic.urls.length){
                          comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1);
                        }else if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx<MediaQuery.of(context).size.width*0.25&&comicReadingPageLogic.index!=1){
                          comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index-1);
                        }else{
                          comicReadingPageLogic.tools = !comicReadingPageLogic.tools;
                          comicReadingPageLogic.update();
                        }
                      }
                    );
                    }else{
                      return PhotoViewGalleryPageOptions(
                          imageProvider: const AssetImage("images/black.png"),
                      );
                    }
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
                    if(i==0){
                      if(comicReadingPageLogic.order!=1) {
                        comicReadingPageLogic.order -= 1;
                        comicReadingPageLogic.urls.clear();
                        comicReadingPageLogic.isLoading = true;
                        comicReadingPageLogic.tools = false;
                        comicReadingPageLogic.update();
                      }else{
                        comicReadingPageLogic.controller.jumpToPage(1);
                        showMessage(context, "已经是第一章了");
                      }
                    }else if(i==comicReadingPageLogic.urls.length+1){
                      if(comicReadingPageLogic.order!=eps.length){
                        comicReadingPageLogic.order += 1;
                        comicReadingPageLogic.urls.clear();
                        comicReadingPageLogic.isLoading = true;
                        comicReadingPageLogic.tools = false;
                        comicReadingPageLogic.update();
                      }else{
                        comicReadingPageLogic.controller.jumpToPage(i-1);
                        showMessage(context, "已经是最后一章了");
                      }
                    }
                    else{
                      comicReadingPageLogic.index = i;
                      comicReadingPageLogic.update();
                    }
                  },
                ),
              ),
              if(comicReadingPageLogic.tools&&comicReadingPageLogic.index!=0&&comicReadingPageLogic.index!=comicReadingPageLogic.urls.length+1)
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                      color: Theme.of(context).cardColor
                    ),
              )),
              if(comicReadingPageLogic.tools&&comicReadingPageLogic.index!=0&&comicReadingPageLogic.index!=comicReadingPageLogic.urls.length+1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Slider(
                value: comicReadingPageLogic.index.toDouble(),
                min: 1,
                max: comicReadingPageLogic.urls.length.toDouble(),
                divisions: comicReadingPageLogic.urls.length,
                onChanged: (i){
                  comicReadingPageLogic.controller.jumpToPage(i.toInt());
                },
              ),),
              Positioned(
                bottom: 13,
                left: 25,
                child: Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),),
              ),
              if(comicReadingPageLogic.tools)
              Positioned(
                  bottom: 0,
                  right: 25,
                  child: Tooltip(
                    message: "章节",
                    child: IconButton(
                      icon: const Icon(Icons.library_books),
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
