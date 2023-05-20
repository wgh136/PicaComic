import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pic_views/login_page.dart';
import 'package:pica_comic/views/pic_views/register.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    network.updateApi();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size(double.infinity,0),
        child: AppBar(),
      ),
      body: Center(
        child: SizedBox(
          width: 200,
          height: 300,
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
                      child: FilledButton(onPressed: () => Get.to(()=>const LoginPage()), child: Text("登录".tr)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 90,
                      child: FilledButton(onPressed: () => Get.to(()=>const RegisterPage()), child: Text("注册".tr)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                height: 40,
                child: Center(
                  child: TextButton(
                    child: Text("直接进入".tr),
                    onPressed: () => Get.offAll(()=>const MainPage()),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
