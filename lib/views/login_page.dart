import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/register.dart';
import '../network/methods.dart';
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
  var isLogging = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登录'),
        actions: [
          Tooltip(
            message: "转到注册",
            child: TextButton(
              child: const Text("转到注册"),
              onPressed: (){Get.off(()=>RegisterPage());},
            ),
          )
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 400,
          //decoration: BoxDecoration(border: Border.all(width: 10, color: Colors.lightBlueAccent)),
          child: Column(
            children: <Widget>[
              TextField(
                autofocus: false,
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: "账号",
                    hintText: "账号",
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
                  if(isLogging){
                    return;
                  }else{
                    isLogging = true;
                  }
                  network = Network();
                  var fur = network.login(nameController.text, passwordController.text);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    width: 400,
                    content: Text("登录中"),
                  ));
                  fur.then((b){
                    if(b==1){
                      appdata.token = network.token;
                      var i = network.getProfile();
                      i.then((t){
                        if(t == null){
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            width: 400,
                            content: Text("登录失败"),
                          ));
                          isLogging = false;
                        }
                        else{
                          appdata.user = t;
                          appdata.writeData();
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Get.off(const MainPage());
                        }
                      });
                    }
                    else if(b == 0){
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        width: 400,
                        content: Text("网络错误"),
                      ));
                      isLogging = false;
                    }else{
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        width: 400,
                        content: Text("账号或密码错误"),
                      ));
                      isLogging = false;
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
