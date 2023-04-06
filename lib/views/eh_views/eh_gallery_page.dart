import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:share_plus/share_plus.dart';
import '../comic_reading_page.dart';
import '../show_image_page.dart';
import '../widgets/loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/widgets.dart';

class GalleryPageLogic extends GetxController{
  bool loading = true;
  Gallery? gallery;
  var controller = ScrollController();
  bool showAppbarTitle = false;

  void loadInfo(EhGalleryBrief brief) async{
    gallery = await ehNetwork.getGalleryInfo(brief);
    loading = false;
    update();
  }
  void retry(){
    loading = true;
    update();
  }
}

class EhGalleryPage extends StatelessWidget {
  const EhGalleryPage(this.brief,{Key? key}) : super(key: key);
  final EhGalleryBrief brief;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<GalleryPageLogic>(
        init: GalleryPageLogic(),
        builder: (logic){
          if(logic.loading){
            logic.loadInfo(brief);
            return showLoading(context);
          }else if(logic.gallery == null){
            return showNetworkError(context, logic.retry, eh: true);
          }else{
            logic.controller.addListener(() {
              //检测当前滚动位置, 决定是否显示Appbar的标题
              bool temp = logic.showAppbarTitle;
              logic.showAppbarTitle = logic.controller.position.pixels>
                  boundingTextSize(
                      logic.gallery!.title,
                      const TextStyle(fontSize: 22),
                      maxWidth: MediaQuery.of(context).size.width
                  ).height+50;
              if(temp!=logic.showAppbarTitle) {
                logic.update();
              }
            });
            return CustomScrollView(
              controller: logic.controller,
              slivers: [
                SliverAppBar(
                  surfaceTintColor: logic.showAppbarTitle?null:Colors.transparent,
                  shadowColor: Colors.transparent,
                  title: AnimatedOpacity(
                    opacity: logic.showAppbarTitle?1.0:0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(logic.gallery!.title),
                  ),
                  pinned: true,
                  actions: [
                    Tooltip(
                      message: "分享",
                      child: IconButton(
                        icon: const Icon(Icons.share,),
                        onPressed: () {
                          Share.share(logic.gallery!.title);
                        },
                      ),)
                  ],
                ),

                //标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectableTextCN(
                        text: logic.gallery!.title,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                ),

                buildGalleryInfo(context,logic),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildGalleryInfo(BuildContext context, GalleryPageLogic logic){
    if(UiMode.m1(context)){
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //封面
                buildCover(context, 350, MediaQuery.of(context).size.width, logic),

                const SizedBox(height: 20,),

                ...buildInfoCards(logic, context),
              ],
            ),
          ),
        ),
      );
    }else{
      return SliverToBoxAdapter(child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            //封面
            buildCover(context, 550, MediaQuery.of(context).size.width/2,logic),
            SizedBox(
              width: MediaQuery.of(context).size.width/2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: buildInfoCards(logic, context),
              ),
            ),
          ],
        ),
      ),);
    }
  }

  Widget buildCover(BuildContext context, double height, double width, GalleryPageLogic logic){
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: CachedNetworkImage(
          width: width-50,
          imageUrl: logic.gallery!.coverPath,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      ),
      onTap: ()=>Get.to(()=>ShowImagePage(logic.gallery!.coverPath,eh: true,)),
    );
  }

  List<Widget> buildInfoCards(GalleryPageLogic logic, BuildContext context){
    var res = <Widget>[];
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("uploader"),
    ));
    res.add(buildInfoCard(logic.gallery!.uploader, context));
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("type"),
    ));
    res.add(buildInfoCard(logic.gallery!.type, context));
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("time"),
    ));
    res.add(buildInfoCard(logic.gallery!.time, context));
    for(var key in logic.gallery!.tags.keys){
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        child: Text(key),
      ));
      res.add(Wrap(
        children: [
          for(var s in logic.gallery!.tags[key]!)
            buildInfoCard(s, context),
        ],
      ));
    }
    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 0),
      child: Row(
        children: [
          Expanded(child: FilledButton(
            onPressed: ()=>Get.to(()=>ComicReadingPage("",0,[],logic.gallery!.title,ehUrls: logic.gallery!.urls,)),
            child: const Text("阅读"),
          ),),
        ],
      ),
    ));
    return res;
  }

  Widget buildInfoCard(String title, BuildContext context){
    return GestureDetector(
      onLongPressStart: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: const Text("复制"),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制");
                },
              ),
            ]
        );
      },
      onSecondaryTapUp: (details){
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, details.globalPosition.dx, details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: const Text("复制"),
                onTap: (){
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制");
                },
              ),
            ]
        );
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        elevation: 0,
        color: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: (){
            //TODO
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(title),
          ),
        ),
      ),
    );
  }

  Size boundingTextSize(String text, TextStyle style,  {int maxLines = 2^31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style), maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
  }
}
