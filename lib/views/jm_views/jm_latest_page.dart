import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../foundation/app.dart';
import 'jm_widgets.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';

class JmLatestPageLogic extends GetxController{
  bool loading = true;
  var comics = <JmComicBrief>[];
  String? message;

  void get() async{
    var res = await jmNetwork.getLatest();
    if(!res.error){
      comics.addAll(res.data);
    }else{
      message = res.errorMessage;
    }
    loading = false;
    update();
  }

  void refresh_(){
    comics.clear();
    loading = true;
    update();
  }
}

class JmLatestPage extends StatelessWidget {
  const JmLatestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmLatestPageLogic>(
      builder: (logic){
        if(logic.loading){
          logic.get();
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.comics.isNotEmpty){
          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                        (context, index){
                      return JmComicTile(logic.comics[index]);
                    },
                    childCount: logic.comics.length
                ),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: App.comicTileMaxWidth,
                  childAspectRatio: App.comicTileAspectRatio,
                ),
              ),
            ],
          );
        }else{
          return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
        }
      },
    );
  }
}
