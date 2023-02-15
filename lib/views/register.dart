import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

class RegisterPageLogic extends GetxController{
  var isRegistering = false;
  var nameController = TextEditingController();
  var account = TextEditingController();
  var password = TextEditingController();
  var password2 = TextEditingController();
  var problem1 = TextEditingController();
  var ans1 = TextEditingController();
  var problem2 = TextEditingController();
  var ans2 = TextEditingController();
  var problem3 = TextEditingController();
  var ans3 = TextEditingController();
  var datetime = DateTime(2023);
  var today = DateTime.now();
  String date = "";
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<RegisterPageLogic>(
      init: RegisterPageLogic(),
        builder: (logic){
      return Scaffold(
        appBar: AppBar(
          title: const Text("注册"),
          actions: [
            Tooltip(
              message: "转到登录",
              child: TextButton(
                child: const Text("转到登录"),
                onPressed: (){Get.off(()=>const LoginPage());},
              ),
            )
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(MediaQuery.of(context).size.width/2-250>0?MediaQuery.of(context).size.width/2-250:0, 0, MediaQuery.of(context).size.width/2-250>0?MediaQuery.of(context).size.width/2-250:0, 0),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      TextField(
                        autofocus: false,
                        controller: logic.nameController,
                        decoration: const InputDecoration(
                            labelText: "用户名",
                            prefixIcon: Icon(Icons.person)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.account,
                        decoration: const InputDecoration(
                            labelText: "账号",
                            prefixIcon: Icon(Icons.account_circle)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "密码",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.password2,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "再输一次密码",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.problem1,
                        decoration: const InputDecoration(
                            labelText: "问题1",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.ans1,
                        decoration: const InputDecoration(
                            labelText: "答案1",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.problem2,
                        decoration: const InputDecoration(
                            labelText: "问题2",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.ans2,
                        decoration: const InputDecoration(
                            labelText: "答案2",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.problem3,
                        decoration: const InputDecoration(
                            labelText: "问题3",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      TextField(
                        autofocus: false,
                        controller: logic.ans3,
                        decoration: const InputDecoration(
                            labelText: "答案3",
                            prefixIcon: Icon(Icons.security)
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text("出生日期${logic.date}"),
                        onTap: () async {
                          var result = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2030));
                          if(result!=null) {
                            logic.date = "${result.year}-${result.month}-${result.day}";
                            logic.datetime = result;
                            logic.update();
                          }
                        },
                      ),
                      if(!logic.isRegistering)
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(100, 10, 100, 0),
                          child: ElevatedButton(
                            child: const Text("注册"),
                            onPressed: (){
                              if(logic.password.text!=logic.password2.text){
                                showMessage(context, "两次输入的密码不一致");
                              }else if(logic.password.text.length<8){
                                showMessage(context, "密码至少8位");
                              }else if(logic.ans1.text==""||
                                  logic.ans2.text==""||
                                  logic.ans3.text==""||
                                  logic.date==""||
                                  logic.account.text==""||
                                  logic.nameController.text == ""||
                                  logic.problem1.text == ""||
                                  logic.problem2.text == ""||
                                  logic.problem3.text == ""
                              ){
                                showMessage(context, "请输入完整信息");
                              }else if(logic.today.difference(logic.datetime).inDays<365*18){
                                showMessage(context, "未成年人禁止涩涩!");
                              } else {
                                logic.isRegistering = true;
                                logic.update();
                                network.register(
                                  logic.ans1.text,
                                  logic.ans2.text,
                                  logic.ans3.text,
                                  logic.date,
                                  logic.account.text, "m",
                                  logic.nameController.text,
                                  logic.password.text,
                                  logic.problem1.text,
                                  logic.problem2.text,
                                  logic.problem3.text
                              ).then((s){
                                logic.isRegistering = false;
                                logic.update();
                                if(s == "注册成功"){
                                  network.login(logic.account.text, logic.password.text).then((i){
                                    if(i == 1){
                                      appdata.token = network.token;
                                      network.getProfile().then((t){
                                        if(t == null){
                                          showMessage(context, "注册成功,但再登录时发生网络错误");
                                        }
                                        else{
                                          appdata.user = t;
                                          appdata.writeData();
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          Get.offAll(()=>const MainPage());
                                        }
                                      });
                                    }else{
                                      showMessage(context, "注册成功,但再登录时发生网络错误");
                                    }
                                  });
                                }else{
                                  showMessage(context, s);
                                }
                              });
                              }
                              },
                          ),
                        ),
                      ),
                      if(logic.isRegistering)
                        const CircularProgressIndicator()
                    ],
                  ),
                ),
              )
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 300)),
          ],
        ),
      );
    }
    );
  }
}
