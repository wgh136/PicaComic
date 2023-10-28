import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/tools/translations.dart';

class JmLoginPage extends StatefulWidget {
  const JmLoginPage({Key? key}) : super(key: key);

  @override
  State<JmLoginPage> createState() => _JmLoginPageState();
}

class _JmLoginPageState extends State<JmLoginPage> {
  var nameController = TextEditingController();
  var passwordController = TextEditingController();
  bool logging = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("登录禁漫天堂".tl),),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: 400,
            height: 300,
            child: Column(
              children: [
                TextField(
                  autofocus: false,
                  controller: nameController,
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
                  decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: "密码".tl,
                      hintText: "您的登录密码".tl,
                      prefixIcon: const Icon(Icons.lock)
                  ),
                  obscureText: true,
                  onSubmitted: (s)async{
                    setState(() {
                      logging = true;
                    });
                    var res = await jmNetwork.login(nameController.text, passwordController.text);
                    if(res.error){
                      showMessage(App.globalContext, res.errorMessage!);
                      setState(() {
                        logging = false;
                      });
                    }else{
                      App.globalBack();
                    }
                  },
                ),
                SizedBox.fromSize(size: const Size(5,10),),
                if(!logging)
                  SizedBox(
                    width: 90,
                    child: FilledButton(
                      child: Text("登录".tl),
                      onPressed: ()async{
                        setState(() {
                          logging = true;
                        });
                        var res = await jmNetwork.login(nameController.text, passwordController.text);
                        if(res.error){
                          showMessage(App.globalContext, res.errorMessage!);
                          try {
                            setState(() {
                              logging = false;
                            });
                          }
                          catch(e){
                            //忽视
                          }
                        }else{
                          App.globalBack();
                        }
                      },
                    ),
                  ),
                if(logging)
                  const SizedBox(
                    width: 90,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                SizedBox(
                  width: 70,
                  height: 40,
                  child: TextButton(
                    onPressed: ()=>launchUrlString("https://18comic.vip/signup",mode: LaunchMode.externalApplication),
                    child: Row(
                      children: [
                        Text("注册".tl),
                        const Icon(Icons.arrow_outward,size: 15,)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
