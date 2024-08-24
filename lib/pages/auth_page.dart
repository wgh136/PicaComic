import 'package:flutter/scheduler.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pica_comic/pages/main_page.dart';
import 'package:pica_comic/tools/translations.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  static bool lock = false;

  static bool initial = true;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with WidgetsBindingObserver {
  @override
  void initState() {
    AuthPage.lock = true;
    WidgetsBinding.instance.addObserver(this);
    if(SchedulerBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      auth();
    }
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed && AuthPage.lock && mounted && !inProgress) {
      auth();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: auth,
      child: Scaffold(
        body: PopScope(
          canPop: false,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: SizedBox(
                height: 100,
                child: Column(
                  children: [
                    Icon(
                      Icons.security,
                      size: 40,
                      color: context.colorScheme.secondary,
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text("点击完成身份验证".tl)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool inProgress = false;

  void auth() async {
    if(inProgress) {
      return;
    }
    inProgress = true;
    var res =
        await LocalAuthentication().authenticate(localizedReason: "需要身份验证".tl);
    inProgress = false;
    if (res) {
      AuthPage.lock = false;
      if (AuthPage.initial) {
        App.offAll(() => const MainPage());
      } else {
        App.globalBack();
      }
    }
  }
}
