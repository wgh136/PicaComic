import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';

class EhGalleryTile extends StatelessWidget {
  final EhGalleryBrief gallery;
  final void Function()? onTap;
  final void Function()? onLongTap;
  final bool cached;
  final String? size;
  final String? time;
  const EhGalleryTile(this.gallery,{Key? key,this.onTap,this.size,this.time,this.onLongTap,this.cached=true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var lang = "";
    if(gallery.tags.isNotEmpty&&gallery.tags[0].substring(0,4) == "lang"){
      lang = gallery.tags[0].substring(9);
    }
    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap??() async{
          Get.to(()=>EhGalleryPage(gallery));
        },
        onLongPress: onLongTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
          child: Row(
            children: [
              Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16)
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cached?CachedNetworkImage(
                      imageUrl: gallery.coverPath,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                      height: double.infinity,
                    ):Image.network(
                      gallery.coverPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, url, error) => const Icon(Icons.error),
                      height: double.infinity,
                    )
                  )
              ),
              SizedBox.fromSize(size: const Size(16,5),),
              Expanded(
                flex: 7,
                child: ComicDescription(
                  title: gallery.title,
                  user: gallery.uploader,
                  subDescription: "${gallery.time}  ${gallery.type}  $lang",
                  star: gallery.stars,
                ),
              ),
              //const Center(
              //  child: Icon(Icons.arrow_right),
              //)
            ],
          ),
        )
    );
  }
}

class ComicDescription extends StatelessWidget {
  const ComicDescription({super.key,
    required this.title,
    required this.user,
    required this.subDescription,
    required this.star
  });

  final String title;
  final String user;
  final String subDescription;
  final double star;

  @override
  Widget build(BuildContext context) {
    final s = star ~/ 0.5;
    return Padding(
      padding: const EdgeInsets.fromLTRB(1.0, 0.0, 0.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
            maxLines: 1,
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 1.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      for(int i=0;i<s~/2;i++)
                        Icon(Icons.star,size: 20,color: Theme.of(context).colorScheme.secondary,),
                      if(s%2==1)
                        Icon(Icons.star_half,size: 20,color: Theme.of(context).colorScheme.secondary,),
                      for(int i=0;i<(5 - s~/2 - s%2);i++)
                        const Icon(Icons.star_border,size: 20,)
                    ],
                  ),
                ),
                Text(
                  subDescription,
                  style: const TextStyle(
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}