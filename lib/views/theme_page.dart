//已废弃, 感觉没什么意义, 动态颜色简单美观

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../base.dart';

class ThemePageLogic extends GetxController{
  bool darkMode = appdata.settings[7]=="1";
  bool dynamicColor = appdata.settings[8]=="1";
}

class ThemePage extends StatelessWidget {
  const ThemePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("选择主题"),),
      body: GetBuilder<ThemePageLogic>(
        init: ThemePageLogic(),
        builder: (logic){
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.dark_mode,color: Theme.of(context).colorScheme.secondary),
                        title: const Text("夜间模式跟随系统"),
                        onTap: (){},
                        trailing: Switch(
                          value: logic.darkMode,
                          onChanged: (b){
                            b?appdata.settings[7] = "1":appdata.settings[7]="7";
                            logic.darkMode = b;
                            logic.update();
                            appdata.writeData();
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.hdr_auto,color: Theme.of(context).colorScheme.secondary),
                        title: const Text("使用动态颜色"),
                        onTap: (){},
                        trailing: Switch(
                          value: logic.dynamicColor,
                          onChanged: (b){
                            b?appdata.settings[8] = "1":appdata.settings[8]="7";
                            logic.dynamicColor = b;
                            logic.update();
                            appdata.writeData();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(),),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 30,
                  child: Text("  选择颜色", style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600),),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                  child: Text("  仅在动态颜色不启用或无效时使用", style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500),),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
