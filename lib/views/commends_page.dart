import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/widgets.dart';
import '../network/models.dart';

class CommendsPageLogic extends GetxController{
  bool isLoading = true;
  var commends = Commends([],"",0,0);
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class CommendsPage extends StatelessWidget {
  final String id;
  const CommendsPage(this.id,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CommendsPageLogic>(
        init: CommendsPageLogic(),
        builder: (commendsPageLogic){
        if(commendsPageLogic.isLoading){
          network.getCommends(id).then((c){
            commendsPageLogic.commends = c;
            commendsPageLogic.change();
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else{
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                centerTitle: true,
                title: const Text("评论"),
                actions: [
                  Tooltip(
                    message: "发言",
                    child: IconButton(
                      icon: const Icon(Icons.message_sharp),
                      onPressed: (){
                        showMessage(context, "评论功能还没做");
                      },
                    ),
                  ),
                ],
              ),
              SliverList(delegate: SliverChildBuilderDelegate(
                childCount: commendsPageLogic.commends.commends.length,
                  (context,index){
                    if(index==commendsPageLogic.commends.commends.length-1&&commendsPageLogic.commends.pages!=commendsPageLogic.commends.loaded){
                      network.loadMoreCommends(commendsPageLogic.commends).then((t){commendsPageLogic.update();});
                    }
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(commendsPageLogic.commends.commends[index].avatarUrl),),
                      title: Text(commendsPageLogic.commends.commends[index].name),
                      subtitle: SelectableText(commendsPageLogic.commends.commends[index].text),
                    );
                  }
              )),
            ],
          );
        }
      },),
    );
  }
}
