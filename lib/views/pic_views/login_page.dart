import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/pic_views/register.dart';
import '../../network/picacg_network/methods.dart';
import '../../base.dart';
import '../main_page.dart';

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
        title: const Text('登录哔咔账号'),
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
          height: 300,
          //decoration: BoxDecoration(border: Border.all(width: 10, color: Colors.lightBlueAccent)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
            child: Column(
              children: <Widget>[
                AutofillGroup(child: Column(
                  children: [
                    TextField(
                      autofocus: false,
                      controller: nameController,
                      autofillHints: const [AutofillHints.email],
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
                      autofillHints: const [AutofillHints.password],
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
                          if(b){
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
                          else if(network.status){
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 400,
                              content: network.message=="invalid email or password"?const Text("账号或密码错误"):Text(network.message),
                            ));
                            setState(() {
                              isLogging = false;
                            });
                          }else{
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 400,
                              content: Text("网络错误"),
                            ));
                            setState(() {
                              isLogging = false;
                            });
                          }
                        });
                      },
                    ),
                  ],
                )),
                SizedBox.fromSize(size: const Size(5,10),),
                if(!GetPlatform.isWeb)
                  ListTile(
                    leading: Icon(Icons.change_circle, color: Theme.of(context).colorScheme.primary,),
                    title: const Text("使用转发服务器"),
                    subtitle: const Text("同时使用网络代理工具会减慢速度"),
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
                          if(b){
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
                          else if(network.status){
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 400,
                              content: network.message=="invalid email or password"?const Text("账号或密码错误"):Text(network.message),
                            ));
                            setState(() {
                              isLogging = false;
                            });
                          }else{
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 400,
                              content: Text("网络错误"),
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
      ),
    );
  }
}
