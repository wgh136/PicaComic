import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';
import 'package:pica_comic/views/pic_views/collections_page.dart';
import 'package:pica_comic/views/pic_views/picacg_latest_page.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';


class CategoriesPageLogic extends StateController{
  var categories = <CategoryItem>[];
  bool isLoading = true;
  String? message;

  void refresh_(){
    categories.clear();
    isLoading = true;
    message = null;
    update();
  }

  void get() async{
    var res = await network.getCategories();
    if(res.success){
      categories = res.data;
    }else{
      message = res.errorMessageWithoutNull;
    }
    isLoading = false;
    update();
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Widget buildItem(String title, ImageProvider image, void Function() onTap){
    return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
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
                  child: Image(
                    image: image,
                    errorBuilder: (context, error, stack) => const Icon(Icons.error),
                    fit: BoxFit.cover,
                  ),
                ),),
              SizedBox.fromSize(size: const Size(20,5),),
              Expanded(
                  flex: 11,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600),),
                  )
              ),
            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<CategoriesPageLogic>(
        builder: (categoriesPageLogic){
      if(categoriesPageLogic.isLoading){
        categoriesPageLogic.get();
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(categoriesPageLogic.categories.isNotEmpty){
        return RefreshIndicator(
          child: CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                    childCount: categoriesPageLogic.categories.length+3,
                        (context, i){
                      if(i==0){
                        return buildItem(
                            "本子妹/本子母推荐".tl,
                            const AssetImage("images/collections.jpg"),
                            () => App.to(context, () => const CollectionsPage())
                        );
                      } else if(i==1){
                        return buildItem(
                          "援助哔咔".tl,
                          const AssetImage("images/help.jpg"),
                          () => showDialog(
                              context: context,
                              builder: (dialogContext)=>AlertDialog(
                                title: Text("援助哔咔".tl),
                                content: Text("将在外部浏览器中打开哔咔官方的援助页面, 是否继续?".tl),
                                actions: [
                                  TextButton(onPressed: ()=>App.globalBack(), child: Text("取消".tl)),
                                  TextButton(onPressed: (){
                                    launchUrlString("https://donate.bidobido.xyz",mode: LaunchMode.externalApplication);
                                    App.globalBack();
                                  }, child: Text("继续".tl)),
                                ],
                          )),);
                      }else if(i==2){
                        return buildItem(
                            "最新漫画".tl,
                            const AssetImage("images/latest.png"),
                            () => App.to(context, () => const PicacgLatestPage()));
                      } else {
                        var category = categoriesPageLogic.categories[i-3];
                        return buildItem(
                          category.title,
                          CachedImageProvider(category.path),
                          () => App.to(context,
                                  () => CategoryComicPage(category.title, categoryType: 1,))
                        );
                      }
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 500,
                  childAspectRatio: 3,
                ),
              ),
              SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(App.globalContext!).padding.bottom))
            ],
          ),
          onRefresh: ()async => categoriesPageLogic.refresh_(),
        );
      }else{
        return showNetworkError(categoriesPageLogic.message,
                ()=>categoriesPageLogic.refresh_(), context, showBack: false);
      }
    });
  }
}
