import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../base.dart';

class HtSettings extends StatefulWidget {
  const HtSettings(this.popUp, {super.key});

  final bool popUp;

  static const htUrls = <String>[
    "https://www.wnacg.com",
    "https://www.wn2.lol",
    "https://www.wn3.lol",
    "https://www.wn4.lol",
  ];

  @override
  State<HtSettings> createState() => _HtSettingsState();
}

class _HtSettingsState extends State<HtSettings> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            title: Text("绅士漫画".tl),
          ),
          ListTile(
            leading: const Icon(Icons.domain_rounded),
            title: Text("Domain: ${appdata.settings[31].replaceFirst("https://", "")}"),
            trailing: IconButton(onPressed: () => changeDomain(context), icon: const Icon(Icons.edit)),
          )
        ],
      ),
    );
  }

  void changeDomain(BuildContext context){
    var controller = TextEditingController();

    void onFinished() {
      var text = controller.text;
      if(!text.contains("https://")){
        text = "https://$text";
      }
      Get.back();
      if(!text.isURL){
        showMessage(context, "Invalid URL");
      }else {
        appdata.settings[31] = text;
        appdata.updateSettings();
        setState(() {});
      }
    }

    showDialog(context: context, builder: (context){
      return SimpleDialog(
        title: const Text("Change Domain"),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            width: 400,
            child: TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text("Domain")
              ),
              controller: controller,
              onEditingComplete: onFinished,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onFinished, child: Text("完成".tl)),
              const SizedBox(width: 16,),
            ],
          )
        ],
      );
    });
  }
}