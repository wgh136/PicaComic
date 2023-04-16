import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/pic_views/collections_page.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CategoriesPageLogic extends GetxController{
  var categories = <CategoryItem>[];
  bool isLoading = true;
  void change(){
    isLoading = !isLoading;
    update();
  }

  void refresh_(){
    categories.clear();
    change();
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoriesPageLogic>(
        builder: (categoriesPageLogic){
      if(categoriesPageLogic.isLoading){
        network.getCategories().then((c){
          if(c!=null){
            categoriesPageLogic.categories = c;
          }
          categoriesPageLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(categoriesPageLogic.categories.isNotEmpty){
        return RefreshIndicator(
          child: CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: categoriesPageLogic.categories.length+2,
                        (context, i){
                      if(i==0){
                        return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (){
                              Get.to(()=>const CollectionsPage());
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16)
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: const Image(
                                        image: AssetImage("images/collections.png"),
                                        fit: BoxFit.cover,
                                      ),
                                    ),),
                                  SizedBox.fromSize(size: const Size(20,5),),
                                  const Expanded(
                                      flex: 11,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("本子妹/本子母推荐",style: TextStyle(fontWeight: FontWeight.w600),),
                                      )
                                  ),
                                ],
                              ),
                            )
                        );
                      } else if(i==1){
                        return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: ()=>showDialog(context: context, builder: (dialogContext)=>AlertDialog(
                              title: const Text("援助哔咔"),
                              content: const Text("将在外部浏览器中打开哔咔官方的援助页面, 是否继续?"),
                              actions: [
                                TextButton(onPressed: ()=>Get.back(), child: const Text("取消")),
                                TextButton(onPressed: (){
                                  launchUrlString("https://donate.bidobido.xyz",mode: LaunchMode.externalApplication);
                                  Get.back();
                                }, child: const Text("继续")),
                              ],
                            )),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Container(
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(18)
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: const Image(
                                        image: AssetImage("images/help.jpg"),
                                        fit: BoxFit.cover,
                                      ),
                                    ),),
                                  SizedBox.fromSize(size: const Size(20,5),),
                                  const Expanded(
                                      flex: 11,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text("援助哔咔",style: TextStyle(fontWeight: FontWeight.w600),),
                                      )
                                  ),
                                ],
                              ),
                            )
                        );
                      }
                      else {
                        return CategoryTile(categoriesPageLogic.categories[i-2], () {});
                      }
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 3,
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
            ],
          ),
          onRefresh: ()async => categoriesPageLogic.refresh_(),
        );
      }else{
        return showNetworkError(context, ()=>categoriesPageLogic.change(),showBack: false);
      }
    });
  }
}
