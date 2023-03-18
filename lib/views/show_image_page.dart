import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/save_image.dart';

import '../base.dart';


class ShowImagePage extends StatefulWidget {
  const ShowImagePage(this.url,{Key? key}) : super(key: key);
  final String url;

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
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              Positioned(child: PhotoView(
                minScale: PhotoViewComputedScale.contained*0.9,
                imageProvider: CachedNetworkImageProvider(getImageUrl(url)),
                loadingBuilder: (context,event){
                  return Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: const Center(child: CircularProgressIndicator(),),
                  );
                },
              )),
              if(MediaQuery.of(context).size.shortestSide>changePoint||!GetPlatform.isAndroid)
                Positioned(
                  left: 10,
                  top: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_outlined,size: 30,color: Colors.white70,),
                    onPressed: (){Get.back();},
                  ),
                ),
              Positioned(
                right: 20,
                bottom: 20,
                child: IconButton(
                  icon: const Icon(Icons.download,color: Colors.white70,),
                  onPressed: () async{
                    saveImage(url);
                  },
                ),
              )
            ],
          ),
        ),
    );
  }
}



