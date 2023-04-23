import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/jm_views/jm_favorite_page.dart';
import 'package:pica_comic/views/pic_views/favorites_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';

class AllFavoritesPage extends StatefulWidget {
  const AllFavoritesPage({Key? key}) : super(key: key);

  @override
  State<AllFavoritesPage> createState() => _AllFavoritesPageState();
}

class _AllFavoritesPageState extends State<AllFavoritesPage> with SingleTickerProviderStateMixin{
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: 3, vsync: this);
    Get.put(FavoritesPageLogic());
    Get.put(EhFavouritePageLogic());
    Get.put(JmFavoritePageLogic());
    super.initState();
  }

  @override
  void dispose() {
    Get.find<FavoritesPageLogic>().dispose();
    Get.find<EhFavouritePageLogic>().dispose();
    Get.find<JmFavoritePageLogic>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("收藏夹"),
        actions: [
          Tooltip(
            message: "更多",
            child: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: (){
                showMenu(context: context,
                    position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width-60, 50, MediaQuery.of(context).size.width-60, 50),
                    items: [
                      PopupMenuItem(
                        child: const Text("浏览模式"),
                        onTap: (){
                          Future.delayed(const Duration(microseconds: 200),()=>changeMode(context));
                        },
                      ),
                      if(appdata.settings[11]=="1")
                        PopupMenuItem(
                          child: const Text("跳页"),
                          onTap: ()=>Future.delayed(const Duration(microseconds: 200),() async{
                            Future.delayed(const Duration(milliseconds: 200),(){
                              switch(controller.index){
                                case 0: changePicPage(context);break;
                                case 1: changeEhPage();break;
                                case 2: changeJmPage();break;
                              }
                            });
                          }),
                        )
                    ]
                );
              },
            ),
          )
        ],
      ),
      body: Column(
        children: [
          TabBar(
            splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
            tabs: const [
              Tab(text: "Picacg",),
              Tab(text: "EHentai",),
              Tab(text: "JmComic",)
            ],
            controller: controller,),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: const [
                FavoritesPage(),
                EhFavouritePage(),
                JmFavoritePage()
              ],
            ),
          )
        ],
      ),
    );
  }

  void changeMode(BuildContext context){
    showDialog(context: context, builder: (dialogContext)=>GetBuilder(
        init: RadioLogic(),
        builder: (logic)=>SimpleDialog(
          title: const Text("选择浏览方式"),
          children: [
            const SizedBox(width: 400,),
            ListTile(
              title: const Text("顺序浏览"),
              trailing: Radio(value: 0, groupValue: logic.value, onChanged: (i)=>logic.changeValue(i!)),
              onTap: ()=>logic.changeValue(0),
            ),
            ListTile(
              title: const Text("分页浏览"),
              trailing: Radio(value: 1, groupValue: logic.value, onChanged: (i)=>logic.changeValue(i!)),
              onTap: ()=>logic.changeValue(1),
            )
          ],
        )
    ));
  }

  Future<void> changePicPage(BuildContext context) async{
    var controller = TextEditingController();
    var logic = Get.find<FavoritesPageLogic>();
    String res = "";
    await showDialog(context: context, builder: (dialogContext)=>SimpleDialog(
      title: const Text("切换页面"),
      children: [
        const SizedBox(width: 400,),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
          child: TextField(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "页码",
              suffixText: "输入1-${logic.pages}之间的数字",
            ),
            controller: controller,
            onSubmitted: (s){
              res =  s;
              Get.back();
            },
          ),
        ),
        Center(child: FilledButton(
          child: const Text("提交"),
          onPressed: (){
            res = controller.text;
            Get.back();
          },
        ),)
      ],
    ));
    logic.changePage(res);
  }

  Future<void> changeEhPage() async{
    showMessage(context, "暂不支持");
  }

  Future<void> changeJmPage() async{
    showMessage(context, "暂不支持");
  }
}

class RadioLogic extends GetxController{
  var value = appdata.settings[11]=="0"?0:1;
  void changeValue(int i){
    value = i;
    appdata.settings[11] = i.toString();
    appdata.writeData();
    update();
    Get.back();
    Get.find<FavoritesPageLogic>().change();
    Get.find<EhFavouritePageLogic>().update();
  }
}