import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import '../base.dart';

class BlockingKeywordPageLogic extends GetxController{
  var keywords = appdata.blockingKeyword;
  final controller = TextEditingController();
}

class BlockingKeywordPage extends StatelessWidget {
  BlockingKeywordPage({this.popUp = false,Key? key}) : super(key: key){
    Get.put(BlockingKeywordPageLogic());
  }
  final bool popUp;

  @override
  Widget build(BuildContext context) {
    var tailing = Tooltip(
      message: "添加",
      child: IconButton(
        icon: const Icon(Icons.add),
        onPressed: (){
          showDialog(context: context,
            builder: (dialogContext)=>GetBuilder<BlockingKeywordPageLogic>(builder: (logic)=>SimpleDialog(
              title: const Text("添加屏蔽关键词"),
              children: [
                const SizedBox(width: 400,),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  child: TextField(
                    controller: logic.controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "添加关键词"
                    ),
                  ),
                ),
                Center(
                  child: FilledButton(
                    child: const Text("提交"),
                    onPressed: (){
                      appdata.blockingKeyword.add(logic.controller.text);
                      logic.update();
                      Get.back();
                      logic.controller.text = "";
                      appdata.writeData();
                    },
                  ),
                )
              ],
          )));
        },
      ),
    );

    var widget = GetBuilder<BlockingKeywordPageLogic>(
      builder: (logic){
        return ListView.builder(
          itemCount: logic.keywords.length+2,
          itemBuilder: (context,index){
            if(index==0){
              return appdata.firstUse[0]=="1"?MaterialBanner(
                  forceActionsBelow: true,
                  padding: const EdgeInsets.all(15),
                  leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary,size: 30,),
                  content: const Text("关键词屏蔽仅生效于搜索和分类, 将会在加载时排除作者/汉化组/分类/tag中含有屏蔽关键词的漫画, 分类页面无法屏蔽tag, 因为哔咔没有提供"), actions: [
                TextButton(onPressed: (){
                  appdata.firstUse[0] = "0";
                  appdata.writeData();
                  logic.update();
                }, child: const Text("关闭"))
              ]):const SizedBox(height: 0,);
            }else if(index==1){
              return appdata.firstUse[1]=="1"?MaterialBanner(
                forceActionsBelow: true,
                  padding: const EdgeInsets.all(15),
                  leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary,size: 30,),
                  content: const Text("请不要添加过多的屏蔽关键词, 否则会造成短时间内产生大量网络请求"), actions: [
                TextButton(onPressed: (){
                  appdata.firstUse[1] = "0";
                  appdata.writeData();
                  logic.update();
                }, child: const Text("关闭"))
              ]):const SizedBox(height: 0,);
            }else{
              return ListTile(
                title: Text(logic.keywords[index-2]),
                trailing: IconButton(
                  icon: Icon(Icons.close,color: Theme.of(context).colorScheme.secondary,),
                  onPressed: (){
                    logic.keywords.removeAt(index-2);
                    logic.update();
                    appdata.writeData();
                  },
                ),
              );
            }
          },
        );
      }
    );

    return popUp?
      PopUpWidgetScaffold(title: "关键词屏蔽", body: widget,tailing: tailing,)
        :Scaffold(
          appBar: AppBar(title: const Text("关键词屏蔽"),actions: [tailing],),
          body: widget,
    );
  }
}
