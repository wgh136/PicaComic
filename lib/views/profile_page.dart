import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pica_comic/base.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/me_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../network/methods.dart';

class SloganLogic extends GetxController{
  bool isUploading = false;
  bool status = false;
  bool status2 = false;
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

class PasswordLogic extends GetxController{
  bool isLoading = false;
  var c1 = TextEditingController();
  var c2 = TextEditingController();
  var c3 = TextEditingController();
  int status = -1;
  var errors = [
    "网络错误",
    "旧密码错误",
    "两次输入的密码不一致",
    "密码至少8位"
  ];
}

class ProfilePage extends StatelessWidget {
  const ProfilePage(this.infoController,{this.popUp=false,Key? key}) : super(key: key);
  final InfoController infoController;
  final bool popUp;

  @override
  Widget build(BuildContext context) {
    final body = GetBuilder<ProfileLogic>(
      init: ProfileLogic(),
      builder: (profileLogic){
        return ListView(
          children: [
            const SizedBox(height: 20,),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 150,
              child: Center(
                child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Avatar(size: 150,avatarUrl: appdata.user.avatarUrl==defaultAvatarUrl?null:appdata.user.avatarUrl,frame: appdata.user.frameUrl,)
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Card(
                elevation: 0,
                //color: Theme.of(context).colorScheme.secondaryContainer,
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
                                  title: const Text("更换头像"),
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
                                                final ImagePicker picker = ImagePicker();
                                                final XFile? file = await picker.pickImage(source: ImageSource.gallery);
                                                if (file != null) {
                                                  logic.url = file.path;
                                                  logic.update();
                                                }
                                              }
                                            },
                                          ),
                                          const SizedBox(height: 20,),
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
                      title: const Text("修改密码"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: (){
                        showDialog(context: context, builder: (dialogContext){
                          return GetBuilder<PasswordLogic>(
                            init: PasswordLogic(),
                            builder: (logic){
                              return SimpleDialog(
                                title: const Text("修改密码"),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                    child: SizedBox(
                                      width: 400,
                                      child: Column(
                                        children: [
                                          const Padding(padding: EdgeInsets.all(5),),
                                          TextField(
                                            decoration: const InputDecoration(
                                                labelText: "输入旧密码",
                                                border: OutlineInputBorder()
                                            ),
                                            obscureText: true,
                                            controller: logic.c1,
                                          ),
                                          const Padding(padding: EdgeInsets.all(5),),
                                          TextField(
                                            decoration: const InputDecoration(
                                                labelText: "输入新密码",
                                                border: OutlineInputBorder()
                                            ),
                                            obscureText: true,
                                            controller: logic.c2,
                                          ),
                                          const Padding(padding: EdgeInsets.all(5),),
                                          TextField(
                                            decoration: const InputDecoration(
                                                labelText: "再输一次新密码",
                                                border: OutlineInputBorder()
                                            ),
                                            obscureText: true,
                                            controller: logic.c3,
                                          ),
                                          const Padding(padding: EdgeInsets.all(5),),
                                          if(!logic.isLoading)
                                            FilledButton(
                                              child: const Text("提交"),
                                              onPressed: (){
                                                if(logic.c2.text!=logic.c3.text){
                                                  logic.status = 2;
                                                  logic.update();
                                                }else if(logic.c2.text.length<8){
                                                  logic.status = 3;
                                                  logic.update();
                                                } else{
                                                  logic.isLoading = !logic.isLoading;
                                                  logic.update();
                                                  network.changePassword(logic.c1.text, logic.c2.text).then((b){
                                                    if(b){
                                                      logic.isLoading = !logic.isLoading;
                                                      Get.back();
                                                      showMessage(context, "密码修改成功");
                                                    }else{
                                                      if(network.status){
                                                        logic.status = 1;
                                                        logic.isLoading = !logic.isLoading;
                                                        logic.update();
                                                      }else{
                                                        logic.status = 0;
                                                        logic.isLoading = !logic.isLoading;
                                                        logic.update();
                                                      }
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                          if(logic.isLoading)
                                            const CircularProgressIndicator(),
                                          if(!logic.isLoading&&logic.status!=-1)
                                            const SizedBox(height: 10,),
                                          if(!logic.isLoading&&logic.status!=-1)
                                            SizedBox(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.error_outline),
                                                  const SizedBox(width: 5,),
                                                  Text(logic.errors[logic.status])
                                                ],
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          );
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
                                title: const Text("更改自我介绍"),
                                children: [
                                  SizedBox(
                                    width: 400,
                                    child: Column(
                                      children: [
                                        Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),child: TextField(
                                          maxLines: 5,
                                          controller: logic.controller,
                                          keyboardType: TextInputType.text,
                                          decoration: const InputDecoration(
                                              border: OutlineInputBorder()
                                          ),
                                        ),),
                                        const SizedBox(height: 20,),
                                        if(!logic.isUploading)
                                          FilledButton(onPressed: (){
                                            if(logic.controller.text == ""){
                                              logic.status2 = true;
                                              logic.update();
                                              return;
                                            }
                                            logic.isUploading = true;
                                            logic.status2 = false;
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
                                              width: 100,
                                              height: 30,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error,color: Theme.of(context).colorScheme.error,),
                                                  const Spacer(),
                                                  Text("网络错误",style: TextStyle(color: Theme.of(context).colorScheme.error,),)
                                                ],
                                              )
                                          ),
                                        if(!logic.isUploading&&logic.status2)
                                          SizedBox(
                                              width: 100,
                                              height: 30,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.error,color: Theme.of(context).colorScheme.error,),
                                                  const Spacer(),
                                                  Text("不能为空",style: TextStyle(color: Theme.of(context).colorScheme.error,),)
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
      },);
    if(popUp){
      return PopUpWidgetScaffold(title: "个人信息", body: body);
    }else {
      return Scaffold(
        appBar: AppBar(title: const Text("个人信息"),),
        body: body
    );
    }
  }
}
