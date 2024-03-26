import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../network/download_model.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({this.inPopupWidget = false, Key? key})
      : super(key: key);
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

  void stateUpdater() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    for (var i in downloadManager.downloading) {
      widgets.add(DownloadingTile(
        i,
        () {
          showConfirmDialog(context, "删除".tl, "确认删除下载任务?".tl, () {
            setState(() {
              downloadManager.cancel(i.id);
            });
          });
        },
        stateUpdater,
        key: Key(i.id),
      ));
    }

    downloadManager.addListener(() {
      setState(() {});
    }, () {
      setState(() {});
    });

    final body = ListView.builder(
        itemCount: downloadManager.downloading.length + 1,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (index == 0) {
            return SizedBox(
              height: 60,
              child: MaterialBanner(
                  leading: downloadManager.isDownloading
                      ? const Icon(
                          Icons.downloading,
                          color: Colors.blue,
                        )
                      : const Icon(
                          Icons.pause_circle_outline_outlined,
                          color: Colors.red,
                        ),
                  content: downloadManager.error
                      ? Text("下载出错".tl)
                      : Text("${"@length 项下载任务".tlParams({
                              "length":
                                  downloadManager.downloading.length.toString()
                            })}${downloadManager.isDownloading ? " 下载中".tl : (downloadManager.downloading.isNotEmpty ? " 已暂停".tl : "")}"),
                  actions: [
                    if (downloadManager.downloading.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          downloadManager.isDownloading
                              ? downloadManager.pause()
                              : downloadManager.start();
                          setState(() {});
                        },
                        child: downloadManager.isDownloading
                            ? Text("暂停".tl)
                            : (downloadManager.error
                                ? Text("重试".tl)
                                : Text("继续".tl)),
                      )
                    else
                      const Text(""),
                  ]),
            );
          } else {
            return widgets[index - 1];
          }
        });

    if (widget.inPopupWidget) {
      return PopUpWidgetScaffold(
        title: "下载管理器".tl,
        body: body,
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("下载管理器".tl),
        ),
        body: body,
      );
    }
  }
}

class DownloadingProgressController extends StateController {
  double value = 0.0;
  int downloadPages = 0;
  int pagesCount = 1;
  int? speed;

  void updateStatus(int a, int b, [int? c]) {
    downloadPages = a;
    pagesCount = b;
    speed = c;
    update();
  }
}

class DownloadingTile extends StatelessWidget {
  final DownloadingItem comic;
  final void Function() cancel;
  final void Function() onComicPositionChange;
  const DownloadingTile(this.comic, this.cancel, this.onComicPositionChange,
      {super.key});

  String getProgressText(DownloadingProgressController controller) {
    if (controller.pagesCount == 0) {
      return "获取图片信息...".tl;
    }

    String speedInfo = "";
    if (controller.speed != null) {
      if (controller.speed! < 1024) {
        speedInfo = "${controller.speed}B/s";
      } else if (controller.speed! < 1024 * 1024) {
        speedInfo = "${(controller.speed! / 1024).toStringAsFixed(2)}KB/s";
      } else {
        speedInfo =
            "${(controller.speed! / 1024 / 1024).toStringAsFixed(2)}MB/s";
      }
    }

    String status =
        "${"已下载".tl}${controller.downloadPages}/${controller.pagesCount}";

    if (speedInfo != "") {
      // 此时controller.pagesCount为字节数
      if (controller.pagesCount < 1024) {
        status =
            "${controller.downloadPages}/${controller.pagesCount}B";
      } else if (controller.pagesCount < 1024 * 1024) {
        status =
            "${controller.downloadPages >> 10}/${(controller.pagesCount >> 10)}KB";
      } else if (controller.pagesCount < 1024 * 1024 * 1024) {
        status =
            "${controller.downloadPages >> 20}/${(controller.pagesCount >> 20)}MB";
      } else {
        status =
            "${controller.downloadPages >> 30}/${(controller.pagesCount >> 30)}GB";
      }
    }

    return "$status  $speedInfo";
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: SizedBox(
        height: 114,
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
                    image: CachedImageProvider(comic.cover,
                        headers: {"User-Agent": webUA}),
                    width: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, a, b) {
                      return const Center(
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                )),
            const SizedBox(
              width: 8,
            ),
            Expanded(
                flex: 4,
                child: StateBuilder(
                  init: DownloadingProgressController(),
                  tag: comic.id,
                  builder: (controller) {
                    controller.downloadPages = comic.downloadedPages;
                    controller.pagesCount = comic.totalPages;
                    controller.value = controller.downloadPages /
                        (controller.pagesCount == 0
                            ? 1
                            : controller.pagesCount);
                    comic.updateUi = () {
                      int? speed;
                      if (comic is EhDownloadingItem &&
                          (comic as EhDownloadingItem).downloadType != 0) {
                        speed = (comic as EhDownloadingItem).currentSpeed;
                      }
                      controller.updateStatus(
                          comic.downloadedPages, comic.totalPages, speed);
                    };
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comic.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          getProgressText(controller),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        LinearProgressIndicator(
                          value: controller.value,
                        )
                      ],
                    );
                  },
                )),
            const SizedBox(
              width: 5,
            ),
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
