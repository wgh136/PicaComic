import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/tools/save_image.dart';

import '../tools/key_down_event.dart';

class ComicReadingPageLogic extends GetxController{
  var controller = PageController(initialPage: 1);
  ComicReadingPageLogic(this.order);
  bool isLoading = true;
  int index = 1;
  int order;
  bool tools = false;
  var urls = <String>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ComicReadingPage extends StatefulWidget{
  final String comicId;
  final int order;
  final List<String> eps;
  final String title;
  const ComicReadingPage(this.comicId,this.order,this.eps,this.title,{Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ComicReadingPageState();


}

class _ComicReadingPageState extends State<ComicReadingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final String comicId = widget.comicId;
  late final List<String> eps = widget.eps; //注意: eps的第一个是标题, 不是章节
  late final String title = widget.title;
  late final int order = widget.order;
  bool downloaded = false;
  ListenVolumeController? listenVolume;
  var epsWidgets = <Widget>[];

  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    super.initState();
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if(listenVolume!=null){
      listenVolume!.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawerEnableOpenDragGesture: false,
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: ListView(
          children: epsWidgets,
        ),
      ),
      body: GetBuilder<ComicReadingPageLogic>(
          init: ComicReadingPageLogic(order),
          builder: (comicReadingPageLogic){
            if(comicReadingPageLogic.isLoading){
              downloaded = downloadManager.downloaded.contains(comicId);
              comicReadingPageLogic.index = 1;
              comicReadingPageLogic.controller = PageController(initialPage: 1);
              comicReadingPageLogic.tools = false;
              if(epsWidgets.isEmpty){
                epsWidgets.add(
                  ListTile(
                    leading: Icon(
                      Icons.library_books,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    title: const Text("章节"),
                  ),
                );
              }
              if(epsWidgets.length==1) {
                for (int i = 1; i < eps.length; i++) {
                  epsWidgets.add(ListTile(
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
              if(downloaded){
                downloadManager.getEpLength(comicId, order).then((i){
                  for(int p=0;p<i;p++){
                    comicReadingPageLogic.urls.add("");
                  }
                  comicReadingPageLogic.change();
                });
              } else {
                network.getComicContent(comicId, comicReadingPageLogic.order).then((l){
                comicReadingPageLogic.urls = l;
                comicReadingPageLogic.change();
              });
              }
              return const DecoratedBox(decoration: BoxDecoration(color: Colors.black),child: Center(
                child: CircularProgressIndicator(),
              ),);
            }else if(comicReadingPageLogic.urls.isNotEmpty){
              if(appdata.settings[7]=="1"){
                listenVolume = ListenVolumeController(
                        () {comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index-1);},
                        () {comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1);}
                );
                listenVolume!.listenVolumeChange();
              }
              return WillPopScope(
                  onWillPop: ()async{
                    if(comicReadingPageLogic.tools){
                      return true;
                    }else{
                      comicReadingPageLogic.tools = true;
                      comicReadingPageLogic.update();
                      return false;
                    }
                  },
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        bottom: 0,
                        right: 0,
                        child: Listener(
                          //监听鼠标滚轮
                          onPointerSignal: (pointerSignal){
                            if(pointerSignal is PointerScrollEvent){
                              comicReadingPageLogic.controller.jumpToPage(pointerSignal.scrollDelta.dy>0?comicReadingPageLogic.index+1:comicReadingPageLogic.index-1);
                            }
                          },
                          child: PhotoViewGallery.builder(
                            itemCount: comicReadingPageLogic.urls.length+2,
                            builder: (BuildContext context, int index){
                              if(index<comicReadingPageLogic.urls.length&&!downloaded) {
                                precacheImage(CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])), context);
                              }else if(index<comicReadingPageLogic.urls.length&&downloaded){
                                precacheImage(FileImage(downloadManager.getImage(comicId, order, index)),context);
                              }
                              if(index!=0&&index!=comicReadingPageLogic.urls.length+1) {
                                if(downloaded){
                                  return PhotoViewGalleryPageOptions(
                                      minScale: PhotoViewComputedScale.contained*0.9,
                                      imageProvider: FileImage(downloadManager.getImage(comicId, order, index-1)),
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
                                          if(comicReadingPageLogic.tools){
                                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                          }else{
                                            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
                                          }
                                        }
                                      }
                                  );
                                } else {
                                  return PhotoViewGalleryPageOptions(
                                      minScale: PhotoViewComputedScale.contained*0.9,
                                      imageProvider: CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index-1])),
                                      initialScale: PhotoViewComputedScale.contained,
                                      heroAttributes: PhotoViewHeroAttributes(tag: "$index/${comicReadingPageLogic.urls.length}"),
                                  );
                                }
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
                        )
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTapUp: (detail){
                            if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx>MediaQuery.of(context).size.width*0.75){
                              comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1);
                            }else if(appdata.settings[0]=="1"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx<MediaQuery.of(context).size.width*0.25){
                              comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index-1);
                            }else{
                              comicReadingPageLogic.tools = !comicReadingPageLogic.tools;
                              comicReadingPageLogic.update();
                              if(comicReadingPageLogic.tools){
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                              }else{
                                SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
                              }
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
                              height: 100+Get.bottomBarHeight/2,
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                                  color: Theme.of(context).cardColor
                              ),
                            )),
                      if(comicReadingPageLogic.tools&&comicReadingPageLogic.index!=0&&comicReadingPageLogic.index!=comicReadingPageLogic.urls.length+1)
                        Positioned(
                          bottom: 40+Get.bottomBarHeight/2,
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
                      if(!comicReadingPageLogic.tools)
                        Positioned(
                          bottom: 13,
                          left: 25,
                          child: Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),),
                        )
                      else
                        Positioned(
                          bottom: 13+Get.bottomBarHeight/2,
                          left: 25,
                          child: Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),),
                        ),
                      if(comicReadingPageLogic.tools)
                        Positioned(
                            bottom: Get.bottomBarHeight/2,
                            right: 25,
                            child: Tooltip(
                              message: "章节",
                              child: IconButton(
                                icon: const Icon(Icons.library_books),
                                onPressed: (){
                                  if(MediaQuery.of(context).size.width>600){
                                    _scaffoldKey.currentState!.openEndDrawer();
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      useSafeArea: true,
                                      builder: (context){
                                        return ListView(
                                          children: epsWidgets,
                                        );
                                      }
                                  );
                                  }
                                },
                              ),
                            )
                        ),
                      if(comicReadingPageLogic.tools)
                        Positioned(
                            bottom: Get.bottomBarHeight/2,
                            right: 75,
                            child: Tooltip(
                              message: "保存图片",
                              child: IconButton(
                                icon: const Icon(Icons.download),
                                onPressed: () async{
                                  if(downloaded){
                                    saveImageFromDisk(downloadManager.getImage(comicId, order, comicReadingPageLogic.index-1).path);
                                  }else {
                                    saveImage(comicReadingPageLogic.urls[comicReadingPageLogic.index-1]);
                                  }
                                },
                              ),
                            )
                        ),
                      if(comicReadingPageLogic.tools&&!GetPlatform.isWeb)
                        Positioned(
                            bottom: Get.bottomBarHeight/2,
                            right: 125,
                            child: Tooltip(
                              message: "分享",
                              child: IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () async{
                                  if(downloaded){
                                    shareImageFromDisk(downloadManager.getImage(comicId, order, comicReadingPageLogic.index-1).path);
                                  }else {
                                    shareImageFromCache(comicReadingPageLogic.urls[comicReadingPageLogic.index-1]);
                                  }
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
                            width: MediaQuery.of(context).size.width+MediaQuery.of(context).padding.top,
                            child: Padding(
                              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                              child: Row(
                                children: [
                                  Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                                    message: "返回",
                                    child: IconButton(
                                      iconSize: 25,
                                      icon: const Icon(Icons.arrow_back_outlined),
                                      onPressed: ()=>Get.back(),
                                    ),
                                  ),),
                                  Container(
                                    width: MediaQuery.of(context).size.width-75,
                                    height: 50,
                                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width-75),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Text(title,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20),),
                                    )
                                    ,)
                                ],
                              ),
                            ),
                          ),),
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
                      if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height&&!comicReadingPageLogic.tools)
                        Positioned(
                          left: 5,
                          top: 5,
                          child: IconButton(
                            iconSize: 30,
                            icon: const Icon(Icons.close),
                            onPressed: (){Get.back();},
                          ),),
                    ],
                  ));
            }else{
              return DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: SafeArea(child: Stack(
                    children: [
                        Positioned(
                          left: 8,
                          top: 12,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white70,),
                            onPressed: ()=>Get.back(),
                          ),
                        ),
                      Positioned(
                        top: MediaQuery.of(context).size.height/2-80,
                        left: 0,
                        right: 0,
                        child: const Align(
                          alignment: Alignment.topCenter,
                          child: Icon(Icons.error_outline,size:60, color: Colors.white70,),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: MediaQuery.of(context).size.height/2-10,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: network.status?Text(network.message):const Text("网络错误", style: TextStyle(color: Colors.white70,),),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: MediaQuery.of(context).size.height/2+30,
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: 100,
                              height: 40,
                              child: FilledButton(
                                onPressed: (){
                                    epsWidgets.clear();
                                    comicReadingPageLogic.change();
                                  },
                                child: const Text("重试"),
                              ),
                            )
                        ),
                      ),
                    ],
                  ))
              );
            }
          }
      ),
    );
  }
}
