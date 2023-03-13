import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:get/get.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(microseconds: 200),()=>auth());
    return GestureDetector(
      onTap: ()=>auth(),
      child: Scaffold(
        body: SizedBox(
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
                  const Text("需要身份验证")
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void auth() async{
    var res = await LocalAuthentication().authenticate(localizedReason: "需要身份验证");
    if(res){
      Get.offAll(()=>const MainPage());
    }
  }
}
