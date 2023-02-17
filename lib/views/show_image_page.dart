import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';

class ShowImagePage extends StatelessWidget {
  const ShowImagePage(this.url,{Key? key}) : super(key: key);
  final String url;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(child: PhotoView(
            imageProvider: NetworkImage(url),
            loadingBuilder: (context,event){
              return Container(
                decoration: const BoxDecoration(color: Colors.black),
                child: const Center(child: CircularProgressIndicator(),),
              );
            },
          )),
          Positioned(
            left: 10,
            top: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_outlined,size: 30,),
              onPressed: (){Get.back();},
            ),
          )
        ],
      )
    );
  }
}
