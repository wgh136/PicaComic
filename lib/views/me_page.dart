import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/profile_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import '../base.dart';
import 'favorites_page.dart';

class InfoController extends GetxController{}

class MePage extends StatelessWidget {
  MePage({super.key});
  final infoController = Get.put(InfoController());

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if(UiMode.m1(context))
          SliverAppBar(
            centerTitle: true,
            title: const Text(""),
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
          )
        else
          const SliverAppBar(
            title: Text(""),
          ),
        if(!UiMode.m1(context))
          const SliverPadding(padding: EdgeInsets.only(top: 20),),
        SliverToBoxAdapter(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: const Size(400,220),
                  child: GetBuilder<InfoController>(
                    builder: (logic){
                      return Card(
                          elevation: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Avatar(
                                  size: 150,
                                  avatarUrl: appdata.user.avatarUrl==defaultAvatarUrl?null:appdata.user.avatarUrl,
                                  frame: appdata.user.frameUrl,
                                ),
                              ),
                              Center(
                                child: Text(appdata.user.name,style: const TextStyle(fontWeight: FontWeight.w600,fontSize: 20)),
                              ),
                              Center(
                                child: Text("Lv${appdata.user.level} ${appdata.user.title}",style: const TextStyle(fontWeight: FontWeight.w300,fontSize: 15)),
                              ),
                            ],
                          )
                      );
                    },
                  ),
                ),
                Wrap(
                  children: [
                    mePageItem(context, Icons.badge,()=>showAdaptiveWidget(context, ProfilePage(infoController,popUp: MediaQuery.of(context).size.width>600,)),"个人信息","查看或修改账号信息"),
                    mePageItem(context, Icons.bookmarks,()=>Get.to(()=>const FavoritesPage()),"收藏夹","查看已收藏的漫画"),
                    mePageItem(context, Icons.download_for_offline,()=>Get.to(()=>DownloadPage()),"已下载","管理已下载的漫画"),
                    mePageItem(context, Icons.logout,()=>logout(context),"退出登录","转到登录页面"),
                    if(kDebugMode)
                    mePageItem(context, Icons.bug_report,() async{
                      var uri = Uri.parse("https://www.kokoiro.xyz/ai/dw/wdd");
                      print(uri.path);
                    },"Debug",""),
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}


Widget mePageItem(BuildContext context, IconData icon, void Function() page, String title, String subTitle){
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

void logout(BuildContext context){
  showDialog(context: context, builder: (context){
    return AlertDialog(
      title: const Text("退出登录"),
      content: const Text("要退出登录吗"),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(onPressed: ()=>Get.back(), child: const Text("取消",textAlign: TextAlign.end,)),
        TextButton(onPressed: (){
          appdata.token = "";
          appdata.settings[13] = "0";
          appdata.writeData();
          Get.offAll(const WelcomePage());
        }, child: const Text("确定",textAlign: TextAlign.end))
      ],
    );
  });
}