import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/new_download_model.dart';

import 'cf_image_widgets.dart';

class DownloadingProgressController extends GetxController{
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
  const DownloadingTile(this.comic,this.cancel, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Row(
        children: [
          Expanded(
            flex: 0,
            child: CfCachedNetworkImage(
              width: 80,
              fit: BoxFit.fitHeight,
              imageUrl: getImageUrl(comic.cover),
              errorWidget: (context,a,b){
                return const Center(
                  child: Icon(Icons.error),
                );
              },
          )),
          const SizedBox(width: 5,),
          Expanded(
            flex: 4,
            child: GetBuilder(
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
                    Text("已下载${controller.downloadPages}/${controller.pagesCount}",style: const TextStyle(fontSize: 12),),
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
              height: 100,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: cancel,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
