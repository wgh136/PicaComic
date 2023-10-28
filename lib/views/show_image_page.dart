import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/tools/translations.dart';
import '../foundation/app.dart';

class ShowImagePage extends StatefulWidget {
  const ShowImagePage(this.url, {this.eh = false, Key? key}) : super(key: key);
  final String url;
  final bool eh;

  @override
  State<ShowImagePage> createState() => _ShowImagePageState();
}

class _ShowImagePageState extends State<ShowImagePage> {
  late final String url = widget.url;
  _ShowImagePageState();

  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    super.initState();
  }

  @override
  dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("图片".tl),
        actions: [
          Tooltip(
            message: "保存图片".tl,
            child: IconButton(
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
              onPressed: () async {
                saveImage(getImageUrl(url), "");
              },
            ),
          ),
          Tooltip(
            message: "分享".tl,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () async {
                shareImageFromCache(url, "");
              },
            ),
          ),
        ],
      ),
      body: PhotoView(
        minScale: PhotoViewComputedScale.contained * 0.9,
        imageProvider:
            CachedNetworkImageProvider(widget.eh ? url : getImageUrl(url)),
        loadingBuilder: (context, event) {
          return Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}
