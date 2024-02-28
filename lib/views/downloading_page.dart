import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../network/download_model.dart';


class DownloadingPage extends StatefulWidget {
  const DownloadingPage({this.inPopupWidget=false, Key? key}) : super(key: key);
  final bool inPopupWidget;

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  @override
  void dispose() {
    downloadManager.removeListener();
    super.dispose();
  }

  void stateUpdater(){
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    for(var i in downloadManager.downloading){
      widgets.add(DownloadingTile(i, () {
        showConfirmDialog(context, "删除", "确认删除下载任务?", () {
          setState(() {
            downloadManager.cancel(i.id);
          });
        });
      }, stateUpdater,  key: Key(i.id),));
    }

    downloadManager.addListener((){
      setState(() {});
    }, (){
      setState(() {});
    });

    final body = ListView.builder(
        itemCount: downloadManager.downloading.length+1,
        padding: EdgeInsets.zero,
        itemBuilder: (context,index){
          if(index == 0){
            return SizedBox(
              height: 60,
              child: MaterialBanner(
                  leading: downloadManager.isDownloading?
                  const Icon(Icons.downloading,color: Colors.blue,):
                  const Icon(Icons.pause_circle_outline_outlined,color: Colors.red,),
                  content: downloadManager.error?
                  Text("下载出错".tl):
                  Text("${"@length 项下载任务".tlParams({"length":downloadManager.downloading.length.toString()})}${downloadManager.isDownloading?" 下载中".tl:(downloadManager.downloading.isNotEmpty?" 已暂停".tl:"")}"),
                  actions: [
                    if(downloadManager.downloading.isNotEmpty)
                      TextButton(
                        onPressed: (){
                          downloadManager.isDownloading?downloadManager.pause():downloadManager.start();
                          setState(() {});
                        },
                        child: downloadManager.isDownloading?
                        Text("暂停".tl):
                        (downloadManager.error?Text("重试".tl):Text("继续".tl)),
                      )
                    else
                      const Text(""),
                  ]
              ),
            );
          }else {
            return widgets[index-1];
          }
        }
    );

    if(widget.inPopupWidget){
      return PopUpWidgetScaffold(
        title: "下载管理器".tl,
        body: body,
      );
    }else{
      return Scaffold(
        appBar: AppBar(title: Text("下载管理器".tl),),
        body: body,
      );
    }
  }
}


class DownloadingProgressController extends StateController{
  double value = 0.0;
  int downloadPages = 0;
  int pagesCount = 1;
  void change(int a, int b){
    downloadPages = a;
    pagesCount = b;
    update();
  }
}

class DownloadingTile extends StatelessWidget {
  final DownloadingItem comic;
  final void Function() cancel;
  final void Function() onComicPositionChange;
  const DownloadingTile(this.comic,this.cancel, this.onComicPositionChange, {super.key});

  String getProgressText(DownloadingProgressController controller){
    if(controller.pagesCount == 0){
      return "获取图片信息...".tl;
    }

    return "${"已下载".tl}${controller.downloadPages}/${controller.pagesCount}";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 100,
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
                flex: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image(
                    image: CachedImageProvider(
                        comic.cover,
                        headers: {
                          "User-Agent": webUA
                        }
                    ),
                    width: 80,
                    fit: BoxFit.fitHeight,
                    errorBuilder: (context,a,b){
                      return const Center(
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                )),
            const SizedBox(width: 5,),
            Expanded(
                flex: 4,
                child: StateBuilder(
                  init: DownloadingProgressController(),
                  tag: comic.id,
                  builder: (controller){
                    controller.downloadPages = comic.downloadedPages;
                    controller.pagesCount = comic.totalPages;
                    controller.value = controller.downloadPages/(controller.pagesCount==0?1:controller.pagesCount);
                    comic.updateUi = (){
                      controller.change(comic.downloadedPages,comic.totalPages);
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(comic.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),maxLines: 3,overflow: TextOverflow.ellipsis,),
                        const Spacer(),
                        Text(getProgressText(controller), style: const TextStyle(fontSize: 12),),
                        const SizedBox(height: 3,),
                        LinearProgressIndicator(
                          value: controller.value,
                        )
                      ],
                    );
                  },
                )
            ),
            const SizedBox(width: 5,),
            Expanded(
              flex: 0,
              child: SizedBox(
                width: 50,
                child: Column(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: cancel,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.vertical_align_top),
                      onPressed: () {
                        DownloadManager().moveToFirst(comic);
                        onComicPositionChange();
                      },
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
