import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/models.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/game_page.dart';

import '../../network/methods.dart';

class GameTile extends StatelessWidget {
  const GameTile(this.game,{Key? key}) : super(key: key);
  final GameItemBrief game;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (){
          Get.to(()=>GamePage(game.id));
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: CachedNetworkImage(
                  imageUrl: getImageUrl(game.iconUrl),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  width: double.infinity,
                  height: 100,
                ),),
              SizedBox.fromSize(size: const Size(20,5),),
              Expanded(
                  flex: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(game.name, style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                          Text(game.publisher)
                        ],
                      ),
                    )
                  )
              ),
            ],
          ),
        )
    );
  }
}
