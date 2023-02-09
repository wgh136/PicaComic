import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets.dart';
import 'base.dart';
import 'favorites_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: CustomScrollView(
      slivers: [
        SliverAppBar.large(
          centerTitle: true,
          title: const Text("我"),
          actions: [
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
        SliverToBoxAdapter(
            child: SizedBox.fromSize(
              size: Size(MediaQuery.of(context).size.width,160),
              child: Card(
                elevation: 0,
                  child: Column(
                    children: [
                      Center(
                        child: SizedBox.fromSize(
                          size: const Size(100,100),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(appdata.user.avatarUrl),
                          ),
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
              ),
            )
        ),
        SliverList(
          delegate: SliverChildListDelegate(
            [
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text("收藏夹"),
                onTap: (){
                  Get.to(()=>FavoritesPage());
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
                          Get.offAll(const LoginPage());
                        }, child: const Text("确定",textAlign: TextAlign.end))
                      ],
                    );
                  });
                },
              ),
            ]
          ),
        )
      ],
    ));
  }
}
