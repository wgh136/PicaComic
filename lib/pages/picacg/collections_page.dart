import 'package:flutter/material.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';

class CollectionPageLogic extends StateController {
  bool isLoading = true;
  var c1 = <ComicItemBrief>[];
  var c2 = <ComicItemBrief>[];
  bool status = true;
  String? message;

  void change() {
    isLoading = !isLoading;
    update();
  }

  void get() async {
    var collections = await network.getCollection();
    if (collections.success) {
      c1 = collections.data[0];
      c2 = collections.data[1];
      change();
    } else {
      status = false;
      message = collections.errorMessageWithoutNull;
      change();
    }
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("推荐".tl),
      ),
      body: StateBuilder<CollectionPageLogic>(
        init: CollectionPageLogic(),
        builder: (logic) {
          if (logic.isLoading) {
            network.getCollection().then((collections) {
              if (collections.success) {
                logic.c1 = collections.data[0];
                logic.c2 = collections.data[1];
                logic.change();
              } else {
                logic.status = false;
                logic.change();
              }
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (logic.status) {
            return CustomScrollView(
              slivers: [
                SliverGridComics(
                  comics: logic.c1 + logic.c2,
                  sourceKey: 'picacg',
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(App.globalContext!).padding.bottom,
                  ),
                )
              ],
            );
          } else {
            return NetworkError(
              message: logic.message ?? "网络错误".tl,
              retry: () {
                logic.status = true;
                logic.change();
              },
            );
          }
        },
      ),
    );
  }
}
