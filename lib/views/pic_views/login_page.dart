import 'package:flutter/material.dart';
import 'package:pica_comic/views/pic_views/register.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../foundation/app.dart';
import '../../network/picacg_network/methods.dart';
import '../../base.dart';
import 'package:pica_comic/tools/translations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var nameController = TextEditingController(text: appdata.picacgAccount);
  var passwordController = TextEditingController(text: appdata.picacgPassword);
  var isLogging = false;
  bool useMyServer = appdata.settings[3]=="1";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('登录哔咔账号'.tl),
        actions: [
          Tooltip(
            message: "转到注册".tl,
            child: TextButton(
              child: Text("转到注册".tl),
              onPressed: ()=>App.off(context, ()=>const RegisterPage()),
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
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "账号".tl,
                          hintText: "账号".tl,
                          prefixIcon: const Icon(Icons.person)
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(5),),
                    TextField(
                      controller: passwordController,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: "密码".tl,
                          hintText: "您的登录密码".tl,
                          prefixIcon: const Icon(Icons.lock)
                      ),
                      obscureText: true,
                      onSubmitted: (s){
                        setState(() {
                          isLogging = true;
                        });
                        network = PicacgNetwork();
                        var fur = network.login(nameController.text, passwordController.text);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          behavior: SnackBarBehavior.floating,
                          width: 400,
                          content: Text("登录中".tl),
                        ));
                        fur.then((b){
                          if(b.success){
                            appdata.token = network.token;
                            var i = network.getProfile();
                            i.then((t){
                              if(t.error){
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  width: 400,
                                  content: Text("登录失败".tl),
                                ));
                                setState(() {
                                  isLogging = false;
                                });
                              }
                              else{
                                appdata.user = t.data;
                                appdata.picacgAccount = nameController.text;
                                appdata.picacgPassword = passwordController.text;
                                appdata.writeData();
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                App.globalBack();
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              behavior: SnackBarBehavior.floating,
                              width: 400,
                              content: Text(b.errorMessageWithoutNull),
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
                  ListTile(
                    leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.secondary,),
                    title: const Text("设置"),
                    trailing: const Icon(Icons.arrow_right),
                    onTap: () => NewSettingsPage.open(),
                  ),
                SizedBox.fromSize(size: const Size(5,10),),
                if(!isLogging)
                  SizedBox(
                    width: 90,
                    child: ElevatedButton(
                      onPressed: (){
                        setState(() {
                          isLogging = true;
                        });
                        network = PicacgNetwork();
                        var fur = network.login(nameController.text, passwordController.text);
                        showMessage(context, "登录中".tl);
                        fur.then((b){
                          if(b.success){
                            appdata.token = network.token;
                            var i = network.getProfile();
                            i.then((t){
                              if(t.error){
                                showMessage(context, t.errorMessage??"未知错误".tl);
                                setState(() {
                                  isLogging = false;
                                });
                              }
                              else{
                                appdata.user = t.data;
                                appdata.picacgAccount = nameController.text;
                                appdata.picacgPassword = passwordController.text;
                                appdata.writeData();
                                App.globalBack();
                              }
                            });
                          } else{
                            showMessage(context, b.errorMessageWithoutNull);
                            setState(() {
                              isLogging = false;
                            });
                          }
                        });
                      },
                      child: Text('登录'.tl),
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
