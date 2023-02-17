import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/register.dart';
import '../network/methods.dart';
import '../base.dart';
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
  bool useMyServer = appdata.settings[3]=="1";
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
              onPressed: (){Get.off(()=>const RegisterPage());},
            ),
          )
        ],
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          height: 400,
          //decoration: BoxDecoration(border: Border.all(width: 10, color: Colors.lightBlueAccent)),
          child: Column(
            children: <Widget>[
              TextField(
                autofocus: false,
                controller: nameController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "账号",
                    hintText: "账号",
                    prefixIcon: Icon(Icons.person)
                ),
              ),
              const Padding(padding: EdgeInsets.all(5),),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "密码",
                    hintText: "您的登录密码",
                    prefixIcon: Icon(Icons.lock)
                ),
                obscureText: true,
                onSubmitted: (s){
                  setState(() {
                    isLogging = true;
                  });
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
                          setState(() {
                            isLogging = false;
                          });
                        }
                        else{
                          appdata.user = t;
                          appdata.writeData();
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Get.offAll(const MainPage());
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
                      setState(() {
                        isLogging = false;
                      });
                    }else{
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        width: 400,
                        content: Text("账号或密码错误"),
                      ));
                      setState(() {
                        isLogging = false;
                      });
                    }
                  });
                },
              ),
              SizedBox.fromSize(size: const Size(5,20),),
              if(!GetPlatform.isWeb)
                ListTile(
                  leading: const Icon(Icons.change_circle),
                  title: const Text("使用转发服务器"),
                  subtitle: const Text("自己有魔法会减慢速度"),
                  trailing: Switch(
                    value: useMyServer,
                    onChanged: (b){
                      b?appdata.settings[3] = "1":appdata.settings[3]="0";
                      setState(() {
                        useMyServer = b;
                      });
                      network.updateApi();
                      appdata.writeData();
                    },
                  ),
                  onTap: (){},
                ),
              SizedBox.fromSize(size: const Size(5,20),),
              if(!isLogging)
              SizedBox(
                width: 90,
                child: ElevatedButton(
                  onPressed: (){
                    setState(() {
                      isLogging = true;
                    });
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
                            setState(() {
                              isLogging = false;
                            });
                          }
                          else{
                            appdata.user = t;
                            appdata.writeData();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            Get.offAll(const MainPage());
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
                        setState(() {
                          isLogging = false;
                        });
                      }else{
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          behavior: SnackBarBehavior.floating,
                          width: 400,
                          content: Text("账号或密码错误"),
                        ));
                        setState(() {
                          isLogging = false;
                        });
                      }
                    });
                  },
                  child: const Text('登录'),
                ),
              ),
              if(isLogging)
                const CircularProgressIndicator()
            ],
          ),
        ),
      ),
    );
  }
}
