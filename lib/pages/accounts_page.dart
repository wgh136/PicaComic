import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AccountsPageLogic extends StateController {
  final _reLogin = <String, bool>{};
}

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  AccountsPageLogic get logic => StateController.find<AccountsPageLogic>();

  @override
  Widget build(BuildContext context) {
    var body = StateBuilder<AccountsPageLogic>(
      init: AccountsPageLogic(),
      builder: (logic) {
        return CustomScrollView(
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate(
                buildContent(context).toList(),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: context.padding.bottom),
            )
          ],
        );
      },
    );

    if (PopupIndicatorWidget.maybeOf(context) != null) {
      return PopUpWidgetScaffold(title: "账号管理".tl, body: body);
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text("账号管理".tl),
        ),
        body: body,
      );
    }
  }

  Iterable<Widget> buildContent(BuildContext context) sync* {
    var sources =
        ComicSource.sources.where((element) => element.account != null);
    if (sources.isEmpty) return;

    for (var element in sources) {
      final bool logged = element.isLogin;
      yield Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          element.name,
          style: const TextStyle(fontSize: 20),
        ),
      );
      if (!logged) {
        yield ListTile(
          title: Text("登录".tl),
          onTap: () async {
            if (element.account!.onLogin != null) {
              await element.account!.onLogin!(context);
            }
            if (element.account!.login != null && context.mounted) {
              await context.to(
                () => _LoginPage(
                  login: element.account!.login!,
                  registerWebsite: element.account!.registerWebsite,
                ),
              );
              element.saveData();
            }
            logic.update();
          },
        );
      }
      if (logged) {
        for (var item in element.account!.infoItems) {
          if (item.builder != null) {
            yield item.builder!(context);
          } else {
            yield ListTile(
              title: Text(item.title.tl),
              subtitle: item.data == null ? null : Text(item.data!()),
              onTap: item.onTap,
            );
          }
        }
        if (element.account!.allowReLogin) {
          bool loading = logic._reLogin[element.key] == true;
          yield ListTile(
            title: Text("重新登录".tl),
            subtitle: Text("如果登录失效点击此处".tl),
            onTap: () async {
              if (element.data["account"] == null) {
                showToast(message: "无数据".tl);
                return;
              }
              logic._reLogin[element.key] = true;
              logic.update();
              final List account = element.data["account"];
              var res = await element.account!.login!(account[0], account[1]);
              if (res.error) {
                showToast(message: res.errorMessage!);
              } else {
                showToast(message: "重新登录成功".tl);
              }
              logic._reLogin[element.key] = false;
              logic.update();
            },
            trailing: loading
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
          );
        }
        yield ListTile(
          title: Text("退出登录".tl),
          onTap: () {
            element.data["account"] = null;
            element.account?.logout();
            element.saveData();
            logic.update();
          },
          trailing: const Icon(Icons.logout),
        );
      }
      yield const Divider();
    }
  }

  void setClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(message: "已复制".tl, icon: const Icon(Icons.check));
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({required this.login, this.registerWebsite});

  final LoginFunction login;

  final String? registerWebsite;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  String username = "";
  String password = "";
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        title: Text("登录".tl),
      ),
      body: Column(children: [
        const Spacer(),
        TextField(
          decoration: InputDecoration(
            labelText: "用户名".tl,
            border: const OutlineInputBorder(),
          ),
          onChanged: (s) {
            username = s;
          },
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: "密码".tl,
            border: const OutlineInputBorder(),
          ),
          obscureText: true,
          onChanged: (s) {
            password = s;
          },
          onSubmitted: (s) => login(),
        ),
        const SizedBox(height: 32),
        Button.filled(
          isLoading: loading,
          onPressed: login,
          child: Text("继续".tl),
        ),
        const Spacer(),
        if (widget.registerWebsite != null)
          TextButton(
            onPressed: () => launchUrlString(widget.registerWebsite!),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Text("注册".tl),
              ],
            ),
          ),
        if (UiMode.m1(context))
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
      ]).paddingLeft(32).paddingRight(32).paddingBottom(16),
    );
  }

  void login() {
    if (username.isEmpty || password.isEmpty) {
      showToast(message: "不能为空".tl, icon: const Icon(Icons.error_outline));
      return;
    }
    setState(() {
      loading = true;
    });
    widget.login(username, password).then((value) {
      if (value.error) {
        showToast(message: value.errorMessage!);
        setState(() {
          loading = false;
        });
      } else {
        showToast(message: "登录成功".tl, icon: const Icon(Icons.check));
        if(mounted) {
          context.pop();
        }
      }
    });
  }
}
