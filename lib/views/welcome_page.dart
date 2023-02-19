import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/register.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          height: 250,
          child: Column(
            children: [
              const SizedBox(
                width: 100,
                height: 100,
                child: CircleAvatar(backgroundImage: AssetImage("images/app_icon.png"),),
              ),
              const Padding(padding: EdgeInsets.only(top: 20),child: Text("Pica Comic",style: TextStyle(fontSize: 20),),),
              SizedBox(
                width: 200,
                height: 80,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: FilledButton(onPressed: (){Get.to(()=>const LoginPage());}, child: const Text("登录")),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 90,
                      child: FilledButton(onPressed: (){Get.to(()=>const RegisterPage());}, child: const Text("注册")),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
