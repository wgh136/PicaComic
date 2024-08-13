import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';

import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/tools/translations.dart';

class CookieManagementView extends StatefulWidget {
  const CookieManagementView({super.key});

  @override
  State<CookieManagementView> createState() => _CookieManagementViewState();
}

class _CookieManagementViewState extends State<CookieManagementView> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("cookies"),
      shape: const RoundedRectangleBorder(),
      children: [
        ListTile(
          title: const Text("ipb_member_id"),
          subtitle: Text(EhNetwork().id),
          onTap: () => setClipboard(EhNetwork().id),
        ),
        ListTile(
          title: const Text("ipb_pass_hash"),
          subtitle: Text(EhNetwork().hash),
          onTap: () => setClipboard(EhNetwork().hash),
        ),
        ListTile(
          title: const Text("igneous"),
          subtitle: Text(EhNetwork().igneous),
          onTap: () => setClipboard(EhNetwork().igneous),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String text = EhNetwork().igneous;
                  return AlertDialog(
                    title: const Text("igneous"),
                    content: TextField(
                      controller: TextEditingController(text: text),
                      onChanged: (s) => text = s,
                    ),
                    actions: [
                      TextButton(onPressed: context.pop, child: Text("取消".tl)),
                      TextButton(
                        onPressed: () {
                          EhNetwork().igneous = text;
                          EhNetwork().cookieJar.saveFromResponse(
                            Uri.parse("https://exhentai.org"),
                            [Cookie("igneous", text)],
                          );
                          EhNetwork().cookieJar.saveFromResponse(
                            Uri.parse("https://e-hentai.org"),
                            [Cookie("igneous", text)],
                          );
                          context.pop();
                          setState(() {});
                        },
                        child: Text("确定".tl),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void setClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(message: "已复制".tl, icon: const Icon(Icons.check));
  }
}

void showEhImageLimit(BuildContext context) async {
  bool cancel = false;
  var controller = showLoadingDialog(context, onCancel: () => cancel = true);
  var res = await EhNetwork().getImageLimit();
  if (cancel) return;
  controller.close();
  if (res.error) {
    showToast(message: res.errorMessage!);
  } else {
    showDialog(
      context: App.globalContext!,
      builder: (context) {
        bool loading = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("图片配额".tl),
            content: Text("${"已用".tl}: ${res.data.current}/${res.data.max}\n"
                "${"重置花费".tl}: ${res.data.resetCost}\n"
                "${"可用货币".tl}: ${res.data.kGP}kGP, ${res.data.credits}credits"),
            actions: [
              Button.text(
                onPressed: context.pop,
                child: Text("返回".tl),
              ),
              if (res.data.current > 0)
                Button.text(
                  isLoading: loading,
                  onPressed: () {
                    setState(() {
                      loading = true;
                    });
                    EhNetwork().resetImageLimit().then((value) {
                      if (context.mounted) {
                        context.pop();
                      }
                      if (value) {
                        showToast(message: "重置成功".tl);
                      } else {
                        showToast(message: "Error");
                      }
                    });
                  },
                  child: Text("重置".tl),
                ),
            ],
          );
        });
      },
    );
  }
}
