import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({Key? key}) : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class CategoriesPageLogic extends GetxController{
  var categories = <CategoryItem>[];
  bool isLoading = true;
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class _CategoriesPageState extends State<CategoriesPage> {
  final categoriesPageLogic = Get.put(CategoriesPageLogic());
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoriesPageLogic>(builder: (categoriesPageLogic){
      if(categoriesPageLogic.isLoading){
        network.getCategories().then((c){
          if(c!=null){
            categoriesPageLogic.categories = c;
            c.removeRange(0, 11);
            categoriesPageLogic.change();
          }
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else{
        return CustomScrollView(
          slivers: [
            SliverAppBar.large(
              centerTitle: true,
              title: const Text("分类"),
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
            SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: categoriesPageLogic.categories.length,
                        (context, i){
                      return CategoryTile(categoriesPageLogic.categories[i], () {});
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 5,
                ),
            )
          ],
        );
      }
    });
  }
}
