import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pica_comic/base.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/me_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../network/methods.dart';

class SloganLogic extends GetxController{
  bool isUploading = false;
  bool status = false;
  var controller = TextEditingController();
}

class ChangeAvatarLogic extends GetxController{
  bool isUploading = false;
  String url = "";
  bool success = true;
}

class ProfileLogic extends GetxController{
  var slogan = appdata.user.slogan??"无";
  var url = appdata.user.avatarUrl;
}

class ProfilePage extends StatelessWidget {
  const ProfilePage(this.infoController,{Key? key}) : super(key: key);
  final InfoController infoController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("个人信息"),),
      body: GetBuilder<ProfileLogic>(
        init: ProfileLogic(),
        builder: (profileLogic){
        return ListView(
          children: [
            const SizedBox(height: 20,),
            SizedBox(
              width: Get.size.width,
              height: 100,
              child: Center(
                child: SizedBox(
                    width: 100,
                    height: 100,
                    child: (appdata.user.avatarUrl==defaultAvatarUrl)?const CircleAvatar(
                        backgroundImage: AssetImage("images/avatar.png")
                    ):CircleAvatar(backgroundImage: NetworkImage(getImageUrl(appdata.user.avatarUrl)),)
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width/2-200>0?MediaQuery.of(context).size.width/2-200:0, 20, MediaQuery.of(context).size.width/2-200>0?MediaQuery.of(context).size.width/2-200:0, 0),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("更换头像"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: (){
                        showDialog(context: context, builder: (dialogContext){
                          return GetBuilder<ChangeAvatarLogic>(
                              init: ChangeAvatarLogic(),
                              builder: (logic){
                                return SimpleDialog(
                                  children: [
                                    SizedBox(
                                      width: 300,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 10,),
                                          GestureDetector(
                                            child: Container(
                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(150)),
                                              clipBehavior: Clip.antiAlias,
                                              width: 150,
                                              height: 150,
                                              child: logic.url!=""?Image.file(File(logic.url),fit: BoxFit.cover,):const Image(image: AssetImage("images/select.png"),fit: BoxFit.cover,),
                                            ),
                                            onTap: () async {
                                              if(GetPlatform.isWindows) {
                                                const XTypeGroup typeGroup = XTypeGroup(
                                                  label: 'images',
                                                  extensions: <String>['jpg', 'png'],
                                                );
                                                final XFile? file =
                                                await openFile(
                                                    acceptedTypeGroups: <XTypeGroup>[typeGroup]);
                                                if (file != null) {
                                                  logic.url = file.path;
                                                  logic.update();
                                                }
                                              }else{
                                                final ImagePicker _picker = ImagePicker();
                                                final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
                                                if (file != null) {
                                                  logic.url = file.path;
                                                  logic.update();
                                                }
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 10,),
                                          if(!logic.isUploading)
                                          FilledButton(onPressed: () async {
                                            if(logic.url==""){
                                              showMessage(context, "请先选择图像");
                                            }else{
                                              logic.isUploading = true;
                                              logic.update();
                                              File file = File(logic.url);
                                              var bytes = await file.readAsBytes();
                                              String base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
                                              network.uploadAvatar(base64Image).then((b){
                                                if(b){
                                                  network.getProfile().then((t){
                                                    if(t!=null) {
                                                      appdata.user = t;
                                                      profileLogic.url = appdata.user.avatarUrl;
                                                      profileLogic.update();
                                                      infoController.update();
                                                      Get.back();
                                                      showMessage(context, "上传成功");
                                                    }else{
                                                      logic.success = false;
                                                      logic.isUploading = false;
                                                      logic.update();
                                                    }
                                                  });
                                                }else{
                                                  logic.success = false;
                                                  logic.isUploading = false;
                                                  logic.update();
                                                }
                                              });
                                            }
                                          }, child: const Text("上传")),
                                          if(logic.isUploading)
                                            const CircularProgressIndicator(strokeWidth: 4,),
                                          if(!logic.isUploading&&!logic.success)
                                            SizedBox(
                                              width: 60,
                                              height: 50,
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.error),
                                                  Spacer(),
                                                  Text("失败")
                                                ],
                                              )
                                            )
                                        ],
                                      ),
                                    )
                                  ],
                                );
                              });
                        });
                      },
                    ),
                    ListTile(
                      title: const Text("账号"),
                      subtitle: Text(appdata.user.email),
                      onTap: (){},
                    ),
                    ListTile(
                      title: const Text("用户名"),
                      subtitle: Text(appdata.user.name),
                      onTap: (){},
                    ),
                    ListTile(
                      title: const Text("等级"),
                      subtitle: Text("Lv${appdata.user.level}    ${appdata.user.title}    Exp${appdata.user.exp.toString()}"),
                      onTap: (){},
                    ),
                    ListTile(
                      title: const Text("自我介绍"),
                      subtitle: Text(profileLogic.slogan),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: (){
                        showDialog(context: context, builder: (dialogContext){
                          return GetBuilder<SloganLogic>(
                            init: SloganLogic(),
                            builder: (logic){
                              return SimpleDialog(
                                children: [
                                  SizedBox(
                                    width: 300,
                                    child: Column(
                                      children: [
                                        Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),child:                                   TextField(
                                          controller: logic.controller,
                                          keyboardType: TextInputType.text,
                                        ),),
                                        if(!logic.isUploading)
                                          FilledButton(onPressed: (){
                                            logic.isUploading = true;
                                            logic.update();
                                            network.changeSlogan(logic.controller.text).then((t){
                                              if(t){
                                                appdata.user.slogan = logic.controller.text;
                                                profileLogic.slogan = logic.controller.text;
                                                profileLogic.update();
                                                Get.back();
                                              }else{
                                                logic.isUploading = false;
                                                logic.status = true;
                                                logic.update();
                                              }
                                            });
                                          }, child: const Text("提交")),
                                        if(logic.isUploading)
                                          const CircularProgressIndicator(),
                                        if(!logic.isUploading&&logic.status)
                                          SizedBox(
                                              width: 80,
                                              height: 50,
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.error),
                                                  Spacer(),
                                                  Text("网络错误")
                                                ],
                                              )
                                          ),
                                      ],
                                    ),
                                  )
                                ],
                              );
                            },);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },)
    );
  }
}
