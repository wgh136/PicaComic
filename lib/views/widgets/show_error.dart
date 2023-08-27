import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/cloudflare.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import '../main_page.dart';

///显示错误提示
Widget showNetworkError(String? message, void Function() retry, BuildContext context, {bool showBack=true}){
  return SafeArea(child: Stack(
    children: [
      if(showBack)
        Positioned(
          left: 8,
          top: 12,
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: ()=>MainPage.back(),
          ),
        ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        child: Center(
          child: SizedBox(
            height: 170,
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60,),
                const SizedBox(height: 5,),
                Text((message??"网络错误").tl, textAlign: TextAlign.center,),
                const SizedBox(height: 5,),
                if(message == NhentaiNetwork.needCloudflareChallengeMessage)
                  FilledButton(onPressed: ()=>bypassCloudFlare(retry), child: Text('继续'.tl))
                else
                  FilledButton(onPressed: retry, child: Text('重试'.tl))
              ],
            ),
          ),
        ),
      )
    ],
  ));
}