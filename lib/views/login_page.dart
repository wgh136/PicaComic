import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'base.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
      ),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 400,
          //decoration: BoxDecoration(border: Border.all(width: 10, color: Colors.lightBlueAccent)),
          child: Column(
            children: <Widget>[
              TextField(
                autofocus: true,
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: "用户名",
                    hintText: "用户名或邮箱",
                    prefixIcon: Icon(Icons.person)
                ),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                    labelText: "密码",
                    hintText: "您的登录密码",
                    prefixIcon: Icon(Icons.lock)
                ),
                obscureText: true,
              ),
              SizedBox.fromSize(size: const Size(5,20),),
              ElevatedButton(
                onPressed: (){
                  var fur = network.login(nameController.text, passwordController.text);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("登录中"),
                  ));
                  fur.then((b){
                    if(b){
                      appdata.token = network.token;
                      var i = network.getProfile();
                      i.then((t){
                        if(t == null){
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text("登录失败"),
                          ));}
                        else{
                          appdata.user = t;
                          appdata.writeData();
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Get.off(const MainPage());
                        }
                      });
                    }
                    else{
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("登录失败"),
                      ));
                    }
                  });
                },
                child: const Text('登录'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
