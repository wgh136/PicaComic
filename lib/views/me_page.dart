import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/profile_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
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
        if(MediaQuery.of(context).size.shortestSide<changePoint)
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
        if(MediaQuery.of(context).size.height/2-285-64>0&&MediaQuery.of(context).size.shortestSide>changePoint)
          SliverPadding(padding: EdgeInsets.only(top: (MediaQuery.of(context).size.height)/2-285-64)),
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
                    mePageItem(context, Icons.person,()=>Get.to(()=>ProfilePage(infoController)),"个人信息"),
                    mePageItem(context, Icons.favorite,()=>Get.to(()=>const FavoritesPage()),"收藏夹"),
                    mePageItem(context, Icons.download,()=>Get.to(()=>DownloadPage()),"已下载"),
                    mePageItem(context, Icons.logout,()=>logout(context),"退出登录"),
                    mePageItem(context, Icons.bug_report,(){
                      var notification = Notifications();
                      notification.init().then((v)=>notification.sendNotification("title", "content"));
                    },"Debug"),
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


Widget mePageItem(BuildContext context, IconData icon, void Function() page, String title){
  return Padding(
    padding: const EdgeInsets.all(20),
    child: InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: page,
      child: Container(
        width: MediaQuery.of(context).size.width/2-50>200?200:MediaQuery.of(context).size.width/2-50,
        height: 135,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Center(
                  child: Icon(icon,size: 50,color: Theme.of(context).colorScheme.primary,)
              ),
            ),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: Center(
                child: Text(title,style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
              ),
            )
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
        TextButton(onPressed: (){Get.back();}, child: const Text("取消",textAlign: TextAlign.end,)),
        TextButton(onPressed: (){
          appdata.token = "";
          appdata.history.clear();
          appdata.writeData();
          Get.offAll(const WelcomePage());
        }, child: const Text("确定",textAlign: TextAlign.end))
      ],
    );
  });
}