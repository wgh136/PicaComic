import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/eh_views/eh_login_page.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import '../../base.dart';
import '../pre_search_page.dart';
import '../widgets/selectable_text.dart';

class EhMainPage extends StatelessWidget {
  const EhMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if(UiMode.m1(context))
        SliverAppBar(
          actions: [
            Tooltip(
              message: "搜索",
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: (){
                  Get.to(()=>PreSearchPage());
                },
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 100,
            child: const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(padding: EdgeInsets.fromLTRB(15, 0, 0, 30),child: Text("EHentai",style: TextStyle(fontSize: 28),),),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            child: Center(
              child: Wrap(
                children: [
                  ehPageItem(context, Icons.badge,()=>manageAccount(context),"Eh账户","管理Eh账户"),
                  ehPageItem(context, Icons.home,()=>Get.to(()=>const EhHomePage()),"Eh主页","浏览Eh漫画"),
                  ehPageItem(context, Icons.local_fire_department,()=>Get.to(()=>const EhPopularPage()),"热门","E-Hentai上的热门漫画"),
                  ehPageItem(context, Icons.bookmarks,()=>Get.to(()=>const EhFavouritePage()),"收藏夹","已收藏的Eh漫画"),
                ],
              ),
            ),
          ),
        )
    ]);
    }

    void manageAccount(BuildContext context){
    if(appdata.ehId == ""){
      Get.to(()=>const EhLoginPage());
    }else {
      showDialog(context: context, builder: (dialogContext)=>SimpleDialog(
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 15, 10),
        title: const Text("Eh账户"),
        children: [
          SelectableTextCN(text: "当前账户: ${appdata.ehAccount}"),
          const SizedBox(height: 10,),
          const Text("cookies:"),
          SelectableTextCN(text: "  ipb_member_id: ${appdata.ehId}"),
          SelectableTextCN(text: "  ipb_pass_hash: ${appdata.ehPassHash}"),
          const SizedBox(height: 12,),
          Center(child: FilledButton(child: const Text("退出登录"),onPressed: (){
            appdata.ehPassHash = "";
            appdata.ehId = "";
            appdata.ehAccount = "";
            appdata.writeData();
            Get.back();
          },),)
        ],
      ));
    }
    }
}

Widget ehPageItem(BuildContext context, IconData icon, void Function() page, String title, String subTitle){
  double width;
  double screenWidth = MediaQuery.of(context).size.width;
  double padding = 10.0;
  if(screenWidth>changePoint2){
    screenWidth -= 450;
    width = screenWidth/2 - padding*2;
  }else if(screenWidth>changePoint){
    screenWidth -= 100;
    width = screenWidth/2 - padding*2;
  }else{
    width = screenWidth - padding*4;
  }


  if(width>400){
    width = 400;
  }

  return Padding(
    padding: EdgeInsets.fromLTRB(padding, 5, padding, 5),
    child: InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: page,
      child: Container(
        width: width,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20,),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
                    child: Text(title,style: const TextStyle(fontSize: 22,fontWeight: FontWeight.w600),),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Text(subTitle),
                  )
                ],
              ),
            ),
            const SizedBox(width: 5,),
            Expanded(
                flex: 1,
                child: Center(
                    child: Icon(icon,size: 55,color: Theme.of(context).colorScheme.secondary,)
                )),
          ],
        ),
      ),
    ),
  );
}