import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/views/widgets/scrollable_list/src/item_positions_listener.dart';
import 'package:pica_comic/views/widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/tools/save_image.dart';
import '../tools/key_down_event.dart';

class ComicReadingPageLogic extends GetxController{
  final controller = PageController(initialPage: 1);
  final scrollController = ItemScrollController();
  var scrollListener = ItemPositionsListener.create();
  var cont = ScrollController(keepScrollOffset: false);
  var transformationController = TransformationController();
  ComicReadingPageLogic(this.order);
  bool isLoading = true;
  int index = 1;
  int order;
  bool tools = false;
  bool showSettings = false;
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

  int get length => urls.length;
}

class ComicReadingPage extends StatefulWidget{
  final String comicId;
  final int order;
  final List<String> eps;
  final String title;
  final int initialPage;
  const ComicReadingPage(this.comicId,this.order,this.eps,this.title,{Key? key, this.initialPage=0}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _ComicReadingPageState();


}

class _ComicReadingPageState extends State<ComicReadingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final String comicId = widget.comicId;
  late final List<String> eps = widget.eps; //注意: eps的第一个是标题, 不是章节
  late final String title = widget.title;
  late final int order = widget.order;
  late var initialPage = widget.initialPage;
  bool downloaded = false;
  ListenVolumeController? listenVolume;
  var epsWidgets = <Widget>[];
  late ScrollManager scrollManager;

  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    if(appdata.settings[14]=="1"){
      setKeepScreenOn();
    }
    super.initState();
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if(listenVolume!=null){
      listenVolume!.stop();
    }
    if(appdata.settings[14]=="1"){
      cancelKeepScreenOn();
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
          dispose: (logic){
            if(logic.controller!.order == 1&&logic.controller!.index==1){
              appdata.saveReadInfo(0, 0, comicId);
            }else if(logic.controller!.order == epsWidgets.length-1&&logic.controller!.index==logic.controller!.length){
              appdata.saveReadInfo(0, 0, comicId);
            }else {
              appdata.saveReadInfo(logic.controller!.order, logic.controller!.index, comicId);
            }
          },
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
              if(initialPage != 0){
                //跳转页面
                Future.delayed(const Duration(milliseconds: 300),()=>comicReadingPageLogic.jumpToPage(widget.initialPage));
                initialPage=0;
              }

              if(appdata.settings[7]=="1"){
                listenVolume = ListenVolumeController(
                        ()=>comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index-1),
                        ()=>comicReadingPageLogic.controller.jumpToPage(comicReadingPageLogic.index+1)
                );
                listenVolume!.listenVolumeChange();
              }else if(listenVolume!=null){
                listenVolume!.stop();
                listenVolume = null;
              }
              if(appdata.settings[9]=="4"){
                //当使用自上而下(连续)方式阅读时, 使用ScrollManager管理滑动
                scrollManager = ScrollManager(comicReadingPageLogic.cont);
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
                      if(comicReadingPageLogic.fingers!=2&&appdata.settings[9]=="4") {
                        scrollManager.addOffset(details.delta.dy/comicReadingPageLogic.transformationController.value.getMaxScaleOnAxis());
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
                                if(comicReadingPageLogic.showSettings){
                                  comicReadingPageLogic.showSettings = false;
                                  comicReadingPageLogic.update();
                                  return;
                                }
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
                          //底部工具栏
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              reverseDuration: const Duration(milliseconds: 150),
                              switchInCurve: Curves.fastOutSlowIn,
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                var tween = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0));
                                return SlideTransition(
                                  position: tween.animate(animation),
                                  child: child,
                                );
                              },
                              child: comicReadingPageLogic.tools?Container(
                                height: 105+Get.bottomBarHeight/2,
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
                                    color: Theme.of(context).colorScheme.surface
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8,),
                                    buildSlider(comicReadingPageLogic),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Tooltip(
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
                                        ),
                                        Tooltip(
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
                                        ),
                                        Tooltip(
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
                                        ),
                                        const SizedBox(width: 5,)
                                      ],
                                    )
                                  ],
                                ),
                              ):const SizedBox(width: 0,height: 0,),
                            ),
                          ),
                          //顶部工具栏
                          Positioned(
                            top: 0,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              reverseDuration: const Duration(milliseconds: 150),
                              switchInCurve: Curves.fastOutSlowIn,
                              child: comicReadingPageLogic.tools?Container(
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
                                          onPressed: (){
                                            comicReadingPageLogic.showSettings = !comicReadingPageLogic.showSettings;
                                            comicReadingPageLogic.update();
                                          },
                                        ),
                                      ),),
                                    ],
                                  ),
                                ),
                              ):const SizedBox(width: 0,height: 0,),
                              transitionBuilder: (Widget child, Animation<double> animation) {
                                var tween = Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0));
                                return SlideTransition(
                                  position: tween.animate(animation),
                                  child: child,
                                );
                              },
                            ),),
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
                                  return Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),);
                                },
                              ):Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),)
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
                                  return Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),);
                                },
                              ):Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),)
                          ),
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
                        //设置
                        Positioned(
                          right: 10,
                          top: 60+MediaQuery.of(context).viewPadding.top,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            reverseDuration: const Duration(milliseconds: 150),
                            switchInCurve: Curves.fastOutSlowIn,
                            child: comicReadingPageLogic.showSettings?Container(
                              width: MediaQuery.of(context).size.width>620?600:MediaQuery.of(context).size.width-20,
                              //height: 300,
                              decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.all(Radius.circular(16))
                              ),
                              child: const ReadingSettings(),
                            ):const SizedBox(width: 0,height: 0,),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                          ),
                        ),
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
          return Image.file(
            downloadManager.getImage(comicId, comicReadingPageLogic.order, index),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
          );
        }else{
          final height = Get.width*1.42;
          return CachedNetworkImage(
            imageUrl: getImageUrl(comicReadingPageLogic.urls[index]),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
            placeholder: (context,str)=>SizedBox(height: height,child: const Center(child: CircularProgressIndicator(),),),
            errorWidget: (context,s,d)=>SizedBox(height: height,child: const Center(child: Icon(Icons.error,color: Colors.white12,),),),
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
          child: AbsorbPointer(
            absorbing: comicReadingPageLogic.tools,
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
            ),
          )
      );
    } else {
      return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: AbsorbPointer(
            absorbing: comicReadingPageLogic.tools,
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
      } else {
        if (appdata.settings[9] == "4") {
          return ValueListenableBuilder(
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
          );
        } else {
          return Slider(
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
          );
        }
      }
    }else{
      return const SizedBox(
        height: 0,
      );
    }
  }
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
  bool keepScreenOn = appdata.settings[14]=="1";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 0, 5),
          child: Text("阅读设置",style: TextStyle(fontSize: 18),),
        ),
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
        if(!GetPlatform.isWeb&&GetPlatform.isAndroid)
          ListTile(
            leading: Icon(Icons.screenshot_outlined,color: Theme.of(context).colorScheme.secondary),
            title: const Text("保持屏幕常亮"),
            onTap: (){},
            trailing: Switch(
              value: keepScreenOn,
              onChanged: (b){
                b?setKeepScreenOn():cancelKeepScreenOn();
                b?appdata.settings[14] = "1":appdata.settings[14]="0";
                setState(() {
                  keepScreenOn = b;
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
    appdata.writeData();
    update();
    var logic = Get.find<ComicReadingPageLogic>();
    logic.index = 1;
    logic.urls.clear();
    logic.tools = false;
    logic.showSettings = false;
    logic.change();
    Get.back();
  }
}

class ScrollManager{
  /*
  Flutter并没有提供能够进行放缩的列表, 在InteractiveViewer放入任何可滚动的组件, InteractiveViewer的手势将会失效
  此类用于处理滚动事件, 先禁用InteractiveViewer的子部件的手势, 使InteractiveViewer能够接收到所有手势
  然后用Listener监听原始指针并将信号传入此类
  此类中通过调用InteractiveViewer子组件的ScrollController来控制滚动
   */
  double offset = 0;//缓存滑动偏移值
  ScrollController scrollController;
  ScrollManager(this.scrollController);
  final slowMove = 8.0;//小于此值的滑动判定为缓慢滑动
  bool runningRelease = false;//是否正在进行释放缓存的偏移值
  bool scrolling = false;

  void addOffset(double value){
    //当滑动时调用此函数进行处理
    moveScrollView(value);
  }

  void moveScrollView(double value){
    //移动ScrollView
    scrollController.jumpTo(scrollController.position.pixels-value);
    if(value>slowMove||value<0-slowMove){
      offset += value*4;
      if (!runningRelease) {
        releaseOffset();
      }
    }else{
      offset = 0;
    }
  }

  void releaseOffset() async{
    runningRelease = true;
    while(offset!=0){
      if(scrollController.position.pixels < 0 || scrollController.position.pixels>scrollController.position.maxScrollExtent){
        offset = 0;
        break;
      }
      if(offset < 0.5&&offset > -0.5){
        moveScrollView(offset);
        offset = 0;
        break;
      }
      var value = offset / 20;
      scrollController.jumpTo(scrollController.position.pixels - value);
      offset -= value;
      await Future.delayed(const Duration(milliseconds: 10));
    }
    runningRelease = false;
  }
}