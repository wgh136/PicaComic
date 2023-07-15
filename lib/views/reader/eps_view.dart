import 'package:flutter/material.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:get/get.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'comic_reading_page.dart'
  show ReadingPageData;


class EpsView extends StatefulWidget {
  const EpsView(this.type, this.eps, this.data, {Key? key}) : super(key: key);
  final ReadingType type;
  final List<String> eps;
  final ReadingPageData data;

  @override
  State<EpsView> createState() => _EpsViewState();
}

class _EpsViewState extends State<EpsView> {
  var controller = ItemScrollController();
  var logic = Get.find<ComicReadingPageLogic>();
  var value = false;

  @override
  Widget build(BuildContext context) {
    var type = widget.type;
    var eps = widget.eps.getNoBlankList();
    var data = widget.data;
    var epsWidgets = <Widget>[];
    for(int index = 0;index<eps.length;index++){
      String title = "";
      if(type == ReadingType.jm){
        title = "第 @c 章".trParams({"c": (index+1).toString()});
      }else{
        title = eps[index];
      }
      epsWidgets.add(
          InkWell(
            onTap: (){
              if(type == ReadingType.jm){
                if (logic.order != index+1) {
                  logic.order = index+1;
                  data.target = eps[index];
                  data.epsWidgets.clear();
                  logic.urls.clear();
                  logic.change();
                }
                Navigator.pop(Get.context!);
              }else if(type == ReadingType.picacg){
                if (index+1 != logic.order) {
                  logic.order = index+1;
                  logic.urls = [];
                  logic.change();
                }
                Navigator.pop(Get.context!);
              }
            },
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  const SizedBox(width: 16,),
                  Text(title),
                  const Spacer(),
                  if(data.downloadedEps.contains(index))
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                      ),
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      child: Text("已下载".tr, style: const TextStyle(fontSize: 14),),
                    ),
                  if(logic.order == index+1)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                      ),
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.fromLTRB(5, 2, 5, 2),
                      child: Text("当前".tr, style: const TextStyle(fontSize: 14),),
                    )
                ],
              ),
            ),
          )
      );
    }

    return SizedBox(
      height: 500,
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              children: [
                const SizedBox(width: 16,),
                Icon(Icons.library_books, color: Theme.of(context).colorScheme.secondary,),
                const SizedBox(width: 8,),
                Text("章节".tr, style: const TextStyle(fontSize: 18),),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.my_location_outlined, color: Theme.of(context).colorScheme.secondary,size: 23,),
                  onPressed: (){
                    var length = eps.getNoBlankList().length;
                    if(!value) {
                      controller.jumpTo(index: logic.order-1);
                    } else {
                      controller.jumpTo(index: length - logic.order);
                    }
                  },
                ),
                Text(" 倒序".tr),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: (b)=>setState(() {
                      value = ! value;
                    }),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: ScrollablePositionedList.builder(
            initialScrollIndex: logic.order-1,
            itemCount: eps.getNoBlankList().length,
            itemBuilder: (context, index){
              if(value){
                return epsWidgets[epsWidgets.length - index -1];
              }else{
                return epsWidgets[index];
              }
            },
            scrollController: ScrollController(),
            itemScrollController: controller,
          )),
          SizedBox(height: MediaQuery.of(context).padding.bottom,)
        ],
      ),
    );
  }
}
