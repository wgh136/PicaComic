import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/pic_views/game_page.dart';
import '../main_page.dart';

class GameTile extends StatelessWidget {
  const GameTile(this.game,{Key? key}) : super(key: key);
  final GameItemBrief game;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: (){
          MainPage.to(()=>GamePage(game.id));
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18)
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image(
                    image: CachedImageProvider(game.iconUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) => const Icon(Icons.error),
                    width: double.infinity,
                    height: 100,
                  ),
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
