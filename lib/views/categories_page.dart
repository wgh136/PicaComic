import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
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
            if(MediaQuery.of(context).size.width<changePoint)
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
            if(MediaQuery.of(context).size.width>changePoint)
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
                      return CategoryTile(categoriesPageLogic.categories[i], () {});
                    }
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 600,
                  childAspectRatio: 4,
                ),
            )
          ],
        );
      }else{
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height/2-80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.error_outline,size:60,),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2+20,
              left: MediaQuery.of(context).size.width/2-50,
              child: SizedBox(
                width: 100,
                height: 40,
                child: FilledButton(
                  onPressed: (){
                    categoriesPageLogic.change();
                  },
                  child: const Text("重试"),
                ),
              ),
            ),
          ],
        );
      }
    });
  }
}
