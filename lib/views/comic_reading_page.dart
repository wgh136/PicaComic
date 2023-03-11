import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/scrollable_list/src/item_positions_listener.dart';
import 'package:pica_comic/views/widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/tools/save_image.dart';
import '../tools/key_down_event.dart';

class ComicReadingPageLogic extends GetxController{
  var controller = PageController(initialPage: 1);
  var scrollController = ItemScrollController();
  var scrollListener = ItemPositionsListener.create();
  var cont = ScrollController(keepScrollOffset: false);
  var transformationController = TransformationController();
  ComicReadingPageLogic(this.order);
  bool isLoading = true;
  int index = 1;
  int order;
  bool tools = false;
  var urls = <String>[];
  int fingers = 0;
  void change(){
    isLoading = !isLoading;
    update();
  }
  void jumpToNextPage(){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(index+1);
    }else{
      scrollController.jumpTo(index: index);
    }
  }
  void jumpToLastPage(){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(index-1);
    }else{
      scrollController.jumpTo(index: index-2);
    }
  }
  void jumpToPage(int i){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(i);
    }else{
      scrollController.jumpTo(index: i-1);
    }
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
  var dyTemp = 114514.2;
  bool downloaded = false;
  ListenVolumeController? listenVolume;
  var epsWidgets = <Widget>[];
  double currentScale = 1.0;

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
      backgroundColor: Colors.black,
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
                downloadManager.getEpLength(comicId, comicReadingPageLogic.order).then((i){
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
              }else if(listenVolume!=null){
                listenVolume!.stop();
                listenVolume = null;
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
                  child: Listener(
                    onPointerMove:(details){
                      if(comicReadingPageLogic.fingers!=2) {
                        comicReadingPageLogic.cont.jumpTo(comicReadingPageLogic.cont.position.pixels-details.delta.dy*1.4/comicReadingPageLogic.transformationController.value.getMaxScaleOnAxis());
                      }
                    } ,
                    onPointerUp: (details)=>comicReadingPageLogic.fingers--,
                    onPointerDown: (details)=>comicReadingPageLogic.fingers++,
                    child: Stack(
                      children: [
                        buildComicView(comicReadingPageLogic),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTapUp: (detail){
                              if(appdata.settings[0]=="1"&&appdata.settings[9]!="4"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx>MediaQuery.of(context).size.width*0.75){
                                comicReadingPageLogic.jumpToNextPage();
                              }else if(appdata.settings[0]=="1"&&appdata.settings[9]!="4"&&!comicReadingPageLogic.tools&&detail.globalPosition.dx<MediaQuery.of(context).size.width*0.25){
                                comicReadingPageLogic.jumpToLastPage();
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
                        buildSlider(comicReadingPageLogic),
                        if(!comicReadingPageLogic.tools)
                          Positioned(
                              bottom: 13,
                              left: 25,
                              child: appdata.settings[9]=="4"?ValueListenableBuilder(
                                valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
                                builder: (context, value, child){
                                  try{
                                    comicReadingPageLogic.index = value.first.index + 1;
                                  }
                                  catch(e){
                                    comicReadingPageLogic.index = 0;
                                  }
                                  return Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),);
                                },
                              ):Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),)
                          )
                        else
                          Positioned(
                              bottom: 13+Get.bottomBarHeight/2,
                              left: 25,
                              child: appdata.settings[9]=="4"?ValueListenableBuilder(
                                valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
                                builder: (context, value, child){
                                  try{
                                    comicReadingPageLogic.index = value.first.index + 1;
                                  }
                                  catch(e){
                                    if(appdata.settings[9]=="4") {
                                      comicReadingPageLogic.index = 0;
                                    }
                                  }
                                  return Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),);
                                },
                              ):Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).iconTheme.color:Colors.white),)
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
                                      saveImageFromDisk(downloadManager.getImage(comicId, comicReadingPageLogic.order, comicReadingPageLogic.index-1).path);
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
                                      shareImageFromDisk(downloadManager.getImage(comicId, comicReadingPageLogic.order, comicReadingPageLogic.index-1).path);
                                    }else {
                                      shareImageFromCache(comicReadingPageLogic.urls[comicReadingPageLogic.index-1]);
                                    }
                                  },
                                ),
                              )
                          ),
                        if(comicReadingPageLogic.tools)
                          Positioned(
                              bottom: Get.bottomBarHeight/2,
                              right: 125,
                              child: Tooltip(
                                message: "分享",
                                child: IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () async{
                                    if(downloaded){
                                      shareImageFromDisk(downloadManager.getImage(comicId, comicReadingPageLogic.order, comicReadingPageLogic.index-1).path);
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
                                      width: MediaQuery.of(context).size.width-125,
                                      height: 50,
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width-75),
                                      child: Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(title,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20),),
                                      )
                                      ,),
                                    //const Spacer(),
                                    Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                                      message: "阅读设置",
                                      child: IconButton(
                                        iconSize: 25,
                                        icon: const Icon(Icons.settings),
                                        onPressed: ()=>showReadingSettings(context),
                                      ),
                                    ),),
                                  ],
                                ),
                              ),
                            ),),
                        if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height&&appdata.settings[9]!="4"&&appdata.settings[4]=="1")
                          Positioned(
                            left: 20,
                            top: MediaQuery.of(context).size.height/2-25,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_circle_left),
                              onPressed: (){
                                final value = appdata.settings[9]=="2"?comicReadingPageLogic.index+1:comicReadingPageLogic.index-1;
                                comicReadingPageLogic.jumpToPage(value);
                              },
                              iconSize: 50,
                            ),
                          ),
                        if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height&&appdata.settings[9]!="4"&&appdata.settings[4]=="1")
                          Positioned(
                            right: 20,
                            top: MediaQuery.of(context).size.height/2-25,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_circle_right),
                              onPressed: (){
                                final value = appdata.settings[9]!="2"?comicReadingPageLogic.index+1:comicReadingPageLogic.index-1;
                                comicReadingPageLogic.jumpToPage(value);
                              },
                              iconSize: 50,
                            ),
                          ),
                        if(MediaQuery.of(context).size.width>MediaQuery.of(context).size.height&&!comicReadingPageLogic.tools&&appdata.settings[4]=="1")
                          Positioned(
                            left: 5,
                            top: 5,
                            child: IconButton(
                              iconSize: 30,
                              icon: const Icon(Icons.close),
                              onPressed: ()=>Get.back(),
                            ),),
                      ],
                    ),
                  ));
            }else{
              return buildErrorView(comicReadingPageLogic);
            }
          }
      ),
    );
  }

  Widget buildGallery(ComicReadingPageLogic comicReadingPageLogic){
    return ScrollablePositionedList.builder(
      itemScrollController: comicReadingPageLogic.scrollController,
      itemPositionsListener: comicReadingPageLogic.scrollListener,
      itemCount: comicReadingPageLogic.urls.length,
      addSemanticIndexes: false,
      scrollController: comicReadingPageLogic.cont,
      itemBuilder: (context,index){
        if(index<comicReadingPageLogic.urls.length-1&&!downloaded) {
          precacheImage(CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index+1])), context);
        }else if(index<comicReadingPageLogic.urls.length-1&&downloaded){
          precacheImage(FileImage(downloadManager.getImage(comicId, comicReadingPageLogic.order, index+1)),context);
        }
        if(downloaded){
          return Image.file(downloadManager.getImage(comicId, comicReadingPageLogic.order, index));
        }else{
          return CachedNetworkImage(
            imageUrl: comicReadingPageLogic.urls[index],
            placeholder: (context,str)=>const SizedBox(height: 500,child: Center(child: CircularProgressIndicator(),),),
          );
        }
      },
    );
  }

  Widget buildComicView(ComicReadingPageLogic comicReadingPageLogic){
    if(appdata.settings[9]!="4") {
      return Positioned(
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
              reverse: appdata.settings[9]=="2",
              scrollDirection: appdata.settings[9]!="3"?Axis.horizontal:Axis.vertical,
              itemCount: comicReadingPageLogic.urls.length+2,
              builder: (BuildContext context, int index){
                if(index<comicReadingPageLogic.urls.length&&!downloaded) {
                  precacheImage(CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])), context);
                }else if(index<comicReadingPageLogic.urls.length&&downloaded){
                  precacheImage(FileImage(downloadManager.getImage(comicId, comicReadingPageLogic.order, index)),context);
                }
                if(index!=0&&index!=comicReadingPageLogic.urls.length+1) {
                  if(downloaded){
                    return PhotoViewGalleryPageOptions(
                      minScale: PhotoViewComputedScale.contained*0.9,
                      imageProvider: FileImage(downloadManager.getImage(comicId, comicReadingPageLogic.order, index-1)),
                      initialScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(tag: "$index/${comicReadingPageLogic.urls.length}"),
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
                      backgroundColor: Colors.white12,
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
      );
    } else {
      return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: Listener(
            onPointerSignal: (pointerSignal){
              if(pointerSignal is PointerScrollEvent){
                comicReadingPageLogic.cont.jumpTo(comicReadingPageLogic.cont.position.pixels+pointerSignal.scrollDelta.dy);
              }
            },
            child: InteractiveViewer(
                transformationController: comicReadingPageLogic.transformationController,
                maxScale: GetPlatform.isDesktop?1.0:2.5,
                child: AbsorbPointer(
                  absorbing: true,//使用控制器控制滚动
                  child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      child: buildGallery(comicReadingPageLogic)
                  ),
                )
            ),
          )
      );
    }
  }

  Widget buildErrorView(ComicReadingPageLogic comicReadingPageLogic){
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

  Widget buildSlider(ComicReadingPageLogic comicReadingPageLogic){
    if(comicReadingPageLogic.tools&&comicReadingPageLogic.index!=0&&comicReadingPageLogic.index!=comicReadingPageLogic.urls.length+1) {
      if (appdata.settings[9] != "2" && appdata.settings[9] != "4") {
        return Positioned(
          bottom: 40 + Get.bottomBarHeight / 2,
          left: 0,
          right: 0,
          child: Slider(
            value: comicReadingPageLogic.index.toDouble(),
            min: 1,
            max: comicReadingPageLogic.urls.length.toDouble(),
            divisions: comicReadingPageLogic.urls.length,
            onChanged: (i) {
              comicReadingPageLogic.index = i.toInt();
              comicReadingPageLogic.jumpToPage(i.toInt());
              comicReadingPageLogic.update();
            },
          ),
        );
      } else {
        if (appdata.settings[9] == "4") {
          return Positioned(
            bottom: 40 + Get.bottomBarHeight / 2,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
              builder: (context, value, child) {
                try {
                  comicReadingPageLogic.index = value.first.index + 1;
                } catch (e) {
                  comicReadingPageLogic.index = 0;
                }
                return Slider(
                  value: comicReadingPageLogic.index.toDouble(),
                  min: 1,
                  max: comicReadingPageLogic.urls.length.toDouble(),
                  divisions: comicReadingPageLogic.urls.length,
                  onChanged: (i) {
                    comicReadingPageLogic.index = i.toInt();
                    comicReadingPageLogic.jumpToPage(i.toInt());
                    comicReadingPageLogic.update();
                  },
                );
              },
            ),
          );
        } else {
          return Positioned(
            bottom: 40 + Get.bottomBarHeight / 2,
            left: 0,
            right: 0,
            child: Slider(
              value: comicReadingPageLogic.urls.length.toDouble() -
                  comicReadingPageLogic.index.toDouble() +
                  1,
              min: 1,
              max: comicReadingPageLogic.urls.length.toDouble(),
              divisions: comicReadingPageLogic.urls.length,
              activeColor: Theme.of(context).colorScheme.surfaceVariant,
              inactiveColor: Theme.of(context).colorScheme.primary,
              thumbColor: Theme.of(context).colorScheme.secondary,
              onChanged: (i) {
                comicReadingPageLogic.controller
                    .jumpToPage(comicReadingPageLogic.urls.length - (i.toInt() - 1));
              },
            ),
          );
        }
      }
    }else{
      return const Positioned(
        bottom: 0,
        child: SizedBox(
          height: 0,
        ),
      );
    }
  }
}

void showReadingSettings(BuildContext context) async{
  await showDialog(context: context, builder: (dialogContext){
    return const SimpleDialog(
      title: Text("阅读设置"),
      children: [
        ReadingSettings()
      ],
    );
  });
}

class ReadingSettings extends StatefulWidget {
  const ReadingSettings({Key? key}) : super(key: key);

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool pageChangeValue = appdata.settings[0]=="1";
  bool showThreeButton = appdata.settings[4]=="1";
  bool useVolumeKeyChangePage = appdata.settings[7]=="1";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 0,width: 400,),
        ListTile(
          leading: Icon(Icons.switch_left,color: Theme.of(context).colorScheme.secondary),
          title: const Text("点击屏幕左右区域翻页"),
          trailing: Switch(
            value: pageChangeValue,
            onChanged: (b){
              b?appdata.settings[0] = "1":appdata.settings[0]="0";
              setState(() {
                pageChangeValue = b;
              });
              appdata.writeData();
            },
          ),
          onTap: (){},
        ),
        ListTile(
          leading: Icon(Icons.volume_mute,color: Theme.of(context).colorScheme.secondary),
          title: const Text("使用音量键翻页"),
          subtitle: const Text("仅安卓端有效"),
          trailing: Switch(
            value: useVolumeKeyChangePage,
            onChanged: (b){
              b?appdata.settings[7] = "1":appdata.settings[7]="0";
              setState(() {
                useVolumeKeyChangePage = b;
              });
              appdata.writeData();
              Get.find<ComicReadingPageLogic>().update();
            },
          ),
          onTap: (){},
        ),
        ListTile(
          leading: Icon(Icons.control_camera,color: Theme.of(context).colorScheme.secondary),
          title: const Text("宽屏时显示前进后退关闭按钮"),
          subtitle: const Text("优化鼠标阅读体验"),
          onTap: (){},
          trailing: Switch(
            value: showThreeButton,
            onChanged: (b){
              b?appdata.settings[4] = "1":appdata.settings[4]="0";
              setState(() {
                showThreeButton = b;
              });
              appdata.writeData();
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.chrome_reader_mode,color: Theme.of(context).colorScheme.secondary),
          title: const Text("选择阅读模式"),
          trailing: const Icon(Icons.arrow_right),
          onTap: ()=>setReadingMethod(context),
        )
      ],
    );
  }
}

void setReadingMethod(BuildContext context){
  showDialog(context: context, builder: (BuildContext context) => SimpleDialog(
      title: const Text("选择阅读模式"),
      children: [GetBuilder<ReadingMethodLogic>(
        init: ReadingMethodLogic(),
        builder: (radioLogic){
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 400,),
              ListTile(
                trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从左至右"),
                onTap: (){
                  radioLogic.setValue(1);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从右至左"),
                onTap: (){
                  radioLogic.setValue(2);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从上至下"),
                onTap: (){
                  radioLogic.setValue(3);
                },
              ),
              ListTile(
                trailing: Radio<int>(value: 4,groupValue: radioLogic.value,onChanged: (i){
                  radioLogic.setValue(i!);
                },),
                title: const Text("从上至下(连续)"),
                onTap: (){
                  radioLogic.setValue(4);
                },
              ),
            ],
          );
        },),]
  ));
}

class ReadingMethodLogic extends GetxController{
  var value = int.parse(appdata.settings[9]);

  void setValue(int i){
    value = i;
    appdata.settings[9] = value.toString();
    update();
    var logic = Get.find<ComicReadingPageLogic>();
    logic.index = 1;
    logic.change();
    logic.urls.clear();
    logic.tools = false;
    Get.back();
    Get.back();
  }
}

class AllowMultipleGestureRecognizer extends TapGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

class PinchToZoomGestureRecognizer extends OneSequenceGestureRecognizer {
  final void Function() onScaleStart;
  final void Function() onScaleUpdate;
  final void Function() onScaleEnd;

  PinchToZoomGestureRecognizer({
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
  });

  @override
  String get debugDescription => '$runtimeType';

  Map<int, Offset> pointerPositionMap = {};

  @override
  void addAllowedPointer(PointerEvent event) {
    startTrackingPointer(event.pointer);
    pointerPositionMap[event.pointer] = event.position;
    if (pointerPositionMap.length >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }
  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      pointerPositionMap[event.pointer] = event.position;
      return;
    } else if (event is PointerDownEvent) {
      pointerPositionMap[event.pointer] = event.position;
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
      pointerPositionMap.remove(event.pointer);
    }

    if (pointerPositionMap.length >= 2) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    resolve(GestureDisposition.rejected);
  }
}