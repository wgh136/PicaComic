import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemePageLogic extends GetxController{

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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
