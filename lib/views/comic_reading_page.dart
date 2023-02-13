import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/network/methods.dart';
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
  final List<String> eps; //注意: eps的第一个是标题, 不是章节
  final String title;
  ComicReadingPage(this.comicId,order,this.eps,this.title,{Key? key}) : super(key: key){
    Get.put(ComicReadingPageLogic(order));
  }

  @override
  Widget build(BuildContext context) {
    return
      GetBuilder<ComicReadingPageLogic>(
          builder: (comicReadingPageLogic){
        if(comicReadingPageLogic.isLoading){
          comicReadingPageLogic.index = 1;
          comicReadingPageLogic.controller = PageController(initialPage: 1);
          comicReadingPageLogic.tools = false;
          if(comicReadingPageLogic.epsWidgets.length==1) {
            for (int i = 1; i < eps.length; i++) {
              comicReadingPageLogic.epsWidgets.add(ListTile(
                title: Text(eps[i]),
                onTap: () {
                  if (i != comicReadingPageLogic.order) {
                    comicReadingPageLogic.order = i;
                    comicReadingPageLogic.urls = [];
                    comicReadingPageLogic.change();
                  }
                  Navigator.pop(context);
                },
              ));
            }
          }
          network.getComicContent(comicId, comicReadingPageLogic.order).then((l){
            comicReadingPageLogic.urls = l;
            comicReadingPageLogic.change();
          });
          return const Scaffold(
            body: DecoratedBox(decoration: BoxDecoration(color: Colors.black),child: Center(
              child: CircularProgressIndicator(),
            ),),
          );
        }else if(comicReadingPageLogic.urls.isNotEmpty){
          return Scaffold(
            backgroundColor: comicReadingPageLogic.tools?Theme.of(context).cardColor:Colors.black,
            body: SafeArea(child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: PhotoViewGallery.builder(
                    itemCount: comicReadingPageLogic.urls.length+2,
                    builder: (BuildContext context, int index){
                      if(index<comicReadingPageLogic.urls.length) {
                        precacheImage(NetworkImage(getImageUrl(comicReadingPageLogic.urls[index])), context);
                      }
                      if(index!=0&&index!=comicReadingPageLogic.urls.length+1) {
                        return PhotoViewGalleryPageOptions(
                            minScale: PhotoViewComputedScale.contained*0.9,
                            imageProvider: NetworkImage(getImageUrl(comicReadingPageLogic.urls[index-1])),
                            initialScale: PhotoViewComputedScale.contained,
                            heroAttributes: PhotoViewHeroAttributes(tag: "$index/${comicReadingPageLogic.urls.length}"),
                            onTapUp: (context,detail,value){
                              if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx>MediaQuery.of(context).size.width*0.75){
                                comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1);
                              }else if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx<MediaQuery.of(context).size.width*0.25){
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
                    pageController: comicReadingPageLogic.controller,
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
                        if(comicReadingPageLogic.order!=eps.length-1){
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
                  ),
                if(comicReadingPageLogic.tools)
                  Positioned(
                      top: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          //borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10),bottomLeft: Radius.circular(10))
                        ),
                        width: MediaQuery.of(context).size.width,
                        height: 60,
                        child: Row(
                          children: [
                            Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                              message: "返回",
                              child: IconButton(
                                iconSize: 25,
                                icon: const Icon(Icons.arrow_back_outlined),
                                onPressed: (){Get.back();},
                              ),
                            ),),
                            Container(
                              width: MediaQuery.of(context).size.width-75,
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width-75),
                              child: Text(title,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20),)
                              ,)
                          ],
                        ),
                      )),
                if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height)
                Positioned(
                  left: 20,
                  top: MediaQuery.of(context).size.height/2-25,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_circle_left),
                    onPressed: (){
                      comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index-1);
                    },
                    iconSize: 50,
                  ),
                ),
                if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height)
                Positioned(
                  right: 20,
                  top: MediaQuery.of(context).size.height/2-25,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_circle_right),
                    onPressed: (){
                      comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1);
                    },
                    iconSize: 50,
                  ),
                ),
                if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height)
                Positioned(
                  left: 5,
                    top: 5,
                    child: IconButton(
                      iconSize: 30,
                      icon: const Icon(Icons.close),
                      onPressed: (){Get.back();},
                    ),)
              ],
            )),
          );
        }else{
          return Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.black),
              child: Stack(
                children: [
                  Positioned(top: 0,
                    left: 0,child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),child: Tooltip(
                      message: "返回",
                      child: IconButton(
                        iconSize: 25,
                        icon: const Icon(Icons.arrow_back_outlined),
                        onPressed: (){Get.back();},
                      ),
                    ),),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height/2-80,
                    left: 0,
                    right: 0,
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: Icon(Icons.error_outline,size:60,color: Colors.white60,),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: MediaQuery.of(context).size.height/2-10,
                    child: const Align(
                      alignment: Alignment.topCenter,
                      child: Text("网络错误",style: TextStyle(color: Colors.white60),),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height/2+20,
                    left: MediaQuery.of(context).size.width/2-50,
                    child: SizedBox(
                      width: 100,
                      height: 40,
                      child: FilledButton(
                        onPressed: (){
                          comicReadingPageLogic.epsWidgets.clear();
                          comicReadingPageLogic.change();
                        },
                        child: const Text("重试"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    );
  }
}
