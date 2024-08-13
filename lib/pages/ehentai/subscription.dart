import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/eh_network/eh_models.dart';
import '../../network/res.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(title: Text("EH订阅".tl), actions: [
        Tooltip(
          message: "更多".tl,
          child: IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: (){
              Future.microtask(() => showDialog(context: App.globalContext!, builder: (context){
                return AlertDialog(
                  title: Text("订阅".tl),
                  content: Text("其它漫画源的订阅尚未完成\n如需管理EH订阅, 请前往EH网站".tl),
                  actions: [
                    TextButton(onPressed: ()=>App.globalBack(), child: Text("返回".tl)),
                  ],
                );
              }));
            },
          ),
        )
      ],),
      body: EhSubscriptionComics(),
    );
  }
}


class PageData{
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}

class EhSubscriptionComics extends ComicsPage<EhGalleryBrief>{
  EhSubscriptionComics({super.key});

  final data = PageData();

  @override
  Future<Res<List<EhGalleryBrief>>> getComics(int i) async{
    if(data.galleries == null){
      Res<Galleries> res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/watched");
      if(res.error){
        return Res(null, errorMessage: res.errorMessage);
      }else{
        data.galleries = res.data;
        data.comics[1] = [];
        data.comics[1]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
    }
    if(data.comics[i] != null){
      return Res(data.comics[i]!);
    }else{
      while(data.comics[i] == null){
        data.page++;
        if(! await EhNetwork().getNextPageGalleries(data.galleries!)){
          return const Res(null, errorMessage: "网络错误");
        }
        data.comics[data.page] = [];
        data.comics[data.page]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
      return Res(data.comics[i]);
    }
  }

  @override
  String? get tag => "EhSubscriptionPage";

  @override
  String? get title => null;

  @override
  String get sourceKey => 'ehentai';
}