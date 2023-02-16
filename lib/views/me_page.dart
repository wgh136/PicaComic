import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/views/profile_page.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';
import 'favorites_page.dart';

class InfoController extends GetxController{}

class MePage extends StatelessWidget {
  MePage({super.key});
  final infoController = Get.put(InfoController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: CustomScrollView(
      slivers: [
        if(Get.size.shortestSide<changePoint)
        SliverAppBar(
          centerTitle: true,
          title: const Text(""),
          actions: [
            if(MediaQuery.of(context).size.width<changePoint)
            Tooltip(
              message: "搜索",
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: (){
                  Get.to(()=>SearchPage());
                },
              ),
            ),
          ],
        ),
        if(Get.size.height/2-300>0)
        SliverPadding(padding: EdgeInsets.only(top: Get.size.height/2-300)),
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
                    )
                ),
                Card(
                  margin: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width/2-250>0?MediaQuery.of(context).size.width/2-250:0, 0, MediaQuery.of(context).size.width/2-250>0?MediaQuery.of(context).size.width/2-250:0, 0),
                  elevation: 0,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notes),
                        title: const Text("个人信息"),
                        onTap: (){
                          Get.to(()=>ProfilePage(infoController));
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.favorite),
                        title: const Text("收藏夹",),
                        onTap: (){
                          Get.to(()=>const FavoritesPage());
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.download),
                        title: const Text("已下载"),
                        onTap: (){
                          showMessage(context, "下载功能还没做");
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text("退出登录"),
                        onTap: (){
                          showDialog(context: context, builder: (context){
                            return AlertDialog(
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
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ));
  }
}
