import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/components/components.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key}) : super(key: key);

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  var comics = <DownloadingItem>[];

  @override
  void dispose() {
    downloadManager.removeListener(onChange);
    super.dispose();
  }

  @override
  void initState() {
    downloadManager.addListener(onChange);
    comics = List.from(downloadManager.downloading);
    super.initState();
  }

  void onChange() {
    if(downloadManager.error) {
      setState(() {});
    } else if (downloadManager.downloading.length != comics.length) {
      rebuild();
    } else {
      key.currentState!.updateUi();
    }
  }

  void rebuild() {
    key = GlobalKey<_DownloadingTileState>();
    setState(() {
      comics = List.from(downloadManager.downloading);
    });
  }

  var key = GlobalKey<_DownloadingTileState>();

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    for (var i in comics) {
      var key = Key(i.id);
      if(i == comics.first) {
        key = this.key;
      }

      widgets.add(_DownloadingTile(
        comic: i,
        cancel: () {
          showConfirmDialog(context, "删除".tl, "确认删除下载任务?".tl, () {
            setState(() {
              downloadManager.cancel(i.id);
            });
          });
        },
        onComicPositionChange: rebuild,
        key: key,
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
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
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

class _DownloadingTile extends StatefulWidget {
  const _DownloadingTile({
    required this.comic,
    required this.cancel,
    required this.onComicPositionChange,
    super.key,
  });

  final DownloadingItem comic;

  final void Function() cancel;

  final void Function() onComicPositionChange;

  @override
  State<_DownloadingTile> createState() => _DownloadingTileState();
}

class _DownloadingTileState extends State<_DownloadingTile> {
  late DownloadingItem comic;

  double value = 0.0;
  int downloadPages = 0;
  int? pagesCount;
  int? speed;

  @override
  initState() {
    super.initState();
    comic = widget.comic;
    updateStatistic();
  }

  @override
  void didUpdateWidget(covariant _DownloadingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comic != comic) {
      setState(() {
        comic = widget.comic;
      });
    }
  }

  void updateStatistic() {
    if(comic != DownloadManager().downloading.first) {
      return;
    }
    comic = DownloadManager().downloading.first;
    if (comic is EhDownloadingItem &&
        (comic as EhDownloadingItem).downloadType != 0) {
      speed = (comic as EhDownloadingItem).currentSpeed;
    }
    downloadPages = comic.downloadedPages;
    pagesCount = comic.totalPages;
    if (pagesCount == 0) {
      pagesCount = null;
    }
    if (pagesCount != null && pagesCount! > 0) {
      value = downloadPages / pagesCount!;
    }
  }

  void updateUi() {
    setState(() {
      updateStatistic();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SizedBox(
        height: 114,
        width: double.infinity,
        child: Row(
          children: [
            Container(
              width: 84,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: context.colorScheme.secondaryContainer,
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedImage(
                image: CachedImageProvider(comic.cover,
                    headers: {"User-Agent": webUA}),
                width: 84,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
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
                    getProgressText(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              child: Column(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.cancel,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.vertical_align_top),
                    onPressed: () {
                      DownloadManager().moveToFirst(comic);
                      widget.onComicPositionChange();
                    },
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  String getProgressText() {
    if (pagesCount == null) {
      if (comic == DownloadManager().downloading.first) {
        return "获取图片信息...".tl;
      } else {
        return "";
      }
    }

    String speedInfo = "";
    if (speed != null) {
      speedInfo = "${_bytesToSize(speed!)}/s";
    }

    String status = "${"已下载".tl}$downloadPages/$pagesCount";

    if (speedInfo != "") {
      status = "${_bytesToSize(downloadPages).split(' ').first}"
          "/${_bytesToSize(pagesCount!)}";
    }

    return "$status  $speedInfo";
  }
}
