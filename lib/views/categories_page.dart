import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/collections_page.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

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
  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoriesPageLogic>(
      init: CategoriesPageLogic(),
        builder: (categoriesPageLogic){
      if(categoriesPageLogic.isLoading){
        network.getCategories().then((c){
          if(c!=null){
            categoriesPageLogic.categories = c;
            c.removeRange(0, 11);
          }
          categoriesPageLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(categoriesPageLogic.categories.isNotEmpty){
        return CustomScrollView(
          slivers: [
            if(MediaQuery.of(context).size.shortestSide<=changePoint)
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
            if(MediaQuery.of(context).size.shortestSide>changePoint)
              SliverToBoxAdapter(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: 180,
                  child: const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(padding: EdgeInsets.fromLTRB(15, 0, 0, 30),child: Text("分类",style: TextStyle(fontSize: 28),),),
                  ),
                ),
              ),
            SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: categoriesPageLogic.categories.length,
                        (context, i){
                      if(i==0){
                        return InkWell(
                            onTap: (){
                              Get.to(()=>const CollectionsPage());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 1,
                                    child: Image(
                                      image: AssetImage("images/collections.png"),
                                      fit: BoxFit.fitWidth,
                                    ),),
                                  SizedBox.fromSize(size: const Size(20,5),),
                                  const Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("本子妹/本子母推荐",style: TextStyle(fontWeight: FontWeight.w600),),
                                      )
                                  ),
                                ],
                              ),
                            )
                        );
                      }else {
                        return CategoryTile(categoriesPageLogic.categories[i-1], () {});
                      }
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 4,
                ),
            ),
            SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
          ],
        );
      }else{
        return showNetworkError(context, () {categoriesPageLogic.change();});
      }
    });
  }
}
