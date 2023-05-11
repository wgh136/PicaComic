import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/jm_views/jm_category_page.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import '../../jm_network/jm_main_network.dart';
import '../../jm_network/jm_models.dart';

class JmCategoriesPageLogic extends GetxController{
  bool loading = true;
  List<Category>? categories;
  String? message;

  void change(){
    loading = !loading;
    update();
  }

  void get() async{
    var res = await jmNetwork.getCategories();
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      categories = res.data;
      change();
    }
  }

  void refresh_(){
    categories = null;
    message = null;
    loading = true;
    update();
  }
}

class JmCategoriesPage extends StatelessWidget {
  const JmCategoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmCategoriesPageLogic>(builder: (logic){
      if(logic.loading){
        logic.get();
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(logic.categories != null){
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index)=>InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: ()=>Get.to(()=>JmCategoryPage(logic.categories![index])),
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
                              child: Image.asset(
                                "images/${index+1}.jpg",
                                fit: BoxFit.fill,
                              ),
                            ),),
                          SizedBox.fromSize(size: const Size(20,5),),
                          Expanded(
                              flex: 11,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(logic.categories![index].name,style: const TextStyle(fontWeight: FontWeight.w600),),
                              )
                          ),
                        ],
                      ),
                    )
                ),
                childCount: logic.categories!.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 600,
                childAspectRatio: 3,
              )
            )
          ],
        );
      }else{
        return showNetworkError(logic.message!, logic.refresh_, context);
      }
    });
  }
}
