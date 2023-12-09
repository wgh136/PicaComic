import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/http_proxy.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'app_settings.dart';

class NetworkSettings extends StatefulWidget {
  const NetworkSettings({super.key});

  @override
  State<NetworkSettings> createState() => _NetworkSettingsState();
}

class _NetworkSettingsState extends State<NetworkSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ListTile(
          title: Text("Http Proxy"),
        ),
        ListTile(
          leading: const Icon(Icons.network_ping),
          title: Text("设置代理".tl),
          trailing: const Icon(
            Icons.arrow_right,
          ),
          onTap: () {
            setProxy(context);
          },
        ),
        const ListTile(
          title: Text("hosts"),
        ),
        ListTile(
          leading: const Icon(Icons.dns),
          title: Text("启用".tl),
          trailing: Switch(
            value: appdata.settings[58] == "1",
            onChanged: (value){
              setState(() {
                appdata.settings[58] = value ? "1" : "0";
              });
              appdata.updateSettings();
              if(value){
                HttpProxyServer.reload();
              }
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.rule),
          title: Text("规则".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: (){
            App.globalTo(() => const EditRuleView());
          },
        ),
        ListTile(
          leading: const Icon(Icons.help),
          title: Text("帮助".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: (){
            launchUrlString("https://github.com/wgh136/PicaComic/blob/master/doc/hosts.md");
          },
        ),
      ],
    );
  }
}

class EditRuleView extends StatefulWidget {
  const EditRuleView({super.key});

  @override
  State<EditRuleView> createState() => _EditRuleViewState();
}

class _EditRuleViewState extends State<EditRuleView> {
  final file = File("${App.dataPath}/rule.json");

  late TextEditingController controller;

  @override
  void initState() {
    HttpProxyServer.createConfigFile();
    controller = TextEditingController(text: file.readAsStringSync());
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    file.writeAsStringSync(controller.text, mode: FileMode.writeOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("rule.json"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom),
          child: TextField(
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: const InputDecoration(
                border: InputBorder.none
            ),
            controller: controller,
          ),
        )
      )
    );
  }
}

