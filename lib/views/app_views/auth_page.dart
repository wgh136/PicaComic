import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../base.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  static bool lock = false;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  void initState() {
    AuthPage.lock = true;
    Future.delayed(const Duration(microseconds: 200),()=>auth());
    super.initState();
  }

  @override
  void dispose() {
    AuthPage.lock = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>auth(),
      child: Scaffold(
        body: WillPopScope(
          onWillPop: ()async=>false,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: SizedBox(
                height: 100,
                width: 100,
                child: Column(
                  children: [
                    Icon(Icons.security,size: 40,color: Theme.of(context).colorScheme.secondary,),
                    const SizedBox(height: 5,),
                    Text("需要身份验证".tl)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void auth() async{
    var res = await LocalAuthentication().authenticate(localizedReason: "需要身份验证".tl);
    if(res){
      if(appdata.flag){
        Get.offAll(()=>const MainPage());
      }else{
        Get.back();
      }
    }
  }
}
