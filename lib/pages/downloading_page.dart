import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/components/components.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key})
      : super(key: key);

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  @override
  void dispose() {
    downloadManager.removeListener();
    super.dispose();
  }

  @override
  void initState() {
    downloadManager.addListener(() {
      setState(() {});
    }, () {
      setState(() {});
    });
    super.initState();
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
          () => setState(() {}),
        key: Key(i.id),
      ));
    }

    final body = ListView.builder(
        itemCount: downloadManager.downloading.length + 1,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (index == 0) {
            String downloadStatus;
            if (downloadManager.isDownloading) {
              downloadStatus = " 下载中".tl;
            } else if (downloadManager.downloading.isNotEmpty) {
              downloadStatus = " 已暂停".tl;
            } else {
              downloadStatus = "";
            }

            String downloadTaskText = "@length 项下载任务".tlParams(
                {"length": downloadManager.downloading.length.toString()});

            String displayText = downloadManager.error
                ? "下载出错".tl
                : downloadTaskText + downloadStatus;
            return Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color:
                                Theme.of(context).colorScheme.outlineVariant))),
                height: 48,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                    ),
                    downloadManager.isDownloading
                        ? const Icon(
                            Icons.downloading,
                            color: Colors.blue,
                          )
                        : const Icon(
                            Icons.pause_circle_outline_outlined,
                            color: Colors.red,
                          ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(displayText),
                    const Spacer(),
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
                      ),
                    const SizedBox(
                      width: 16,
                    ),
                  ],
                ));
          } else {
            return widgets[index - 1];
          }
        });

    return PopUpWidgetScaffold(
      title: "下载管理器".tl,
      body: body,
    );
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

  String _bytesToSize(int bytes) {
    if (bytes < 1024) {
      return "$bytes B";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    } else if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / 1024 / 1024).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB";
    }
  }

  String getProgressText(DownloadingProgressController controller) {
    if (controller.pagesCount == 0) {
      if(comic == DownloadManager().downloading.first) {
        return "获取图片信息...".tl;
      } else {
        return "";
      }
    }

    String speedInfo = "";
    if (controller.speed != null) {
      speedInfo = "${_bytesToSize(controller.speed!)}/s";
    }

    String status =
        "${"已下载".tl}${controller.downloadPages}/${controller.pagesCount}";

    if (speedInfo != "") {
      status = "${_bytesToSize(controller.downloadPages).split(' ').first}"
          "/${_bytesToSize(controller.pagesCount)}";
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
                  initState: (controller) {
                    comic.updateUi = () {
                      int? speed;
                      if (comic is EhDownloadingItem &&
                          (comic as EhDownloadingItem).downloadType != 0) {
                        speed = (comic as EhDownloadingItem).currentSpeed;
                      }
                      controller.updateStatus(
                          comic.downloadedPages, comic.totalPages, speed);
                    };
                  },
                  tag: comic.id,
                  builder: (controller) {
                    controller.downloadPages = comic.downloadedPages;
                    controller.pagesCount = comic.totalPages;
                    controller.value = controller.downloadPages /
                        (controller.pagesCount == 0
                            ? 1
                            : controller.pagesCount);
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
