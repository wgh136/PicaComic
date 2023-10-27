import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/tools/translations.dart';
import '../foundation/app.dart';

class ShowImagePage extends StatefulWidget {
  const ShowImagePage(this.url,{this.eh=false,Key? key}) : super(key: key);
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
        body: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
          ),
          child: Stack(
            children: [
              Positioned(child: PhotoView(
                minScale: PhotoViewComputedScale.contained*0.9,
                imageProvider: CachedNetworkImageProvider(widget.eh?url:getImageUrl(url)),
                loadingBuilder: (context,event){
                  return Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: const Center(child: CircularProgressIndicator(),),
                  );
                },
              )),
              //顶部工具栏
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 8,),
                      IconButton(
                        iconSize: 25,
                        icon: const Icon(Icons.arrow_back_outlined,color: Colors.white),
                        onPressed: ()=>App.globalBack(),
                      ),
                      const SizedBox(width: 8,),
                      Expanded(child: Text("图片".tl,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20,color: Colors.white),),),
                      Tooltip(
                        message: "保存图片".tl,
                        child: IconButton(
                          icon: const Icon(Icons.download,color: Colors.white,),
                          onPressed: () async{
                            saveImage(getImageUrl(url),"");
                          },
                        ),
                      ),
                      Tooltip(
                        message: "分享".tl,
                        child: IconButton(
                          icon: const Icon(Icons.share,color: Colors.white),
                          onPressed: () async{
                            shareImageFromCache(url,"");
                          },
                        ),
                      ),
                      const SizedBox(width: 8,),
                    ],
                  ),
                ),),
            ],
          ),
        ),
    );
  }
}



