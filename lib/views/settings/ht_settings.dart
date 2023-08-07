import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/views/widgets/select.dart';
import '../../base.dart';

class HtSettings extends StatelessWidget {
  const HtSettings(this.popUp, {super.key});

  final bool popUp;

  static const htUrls = <String>[
    "https://www.wnacg.com",
    "https://www.wnacg01.ru",
    "https://www.wnacg02.ru",
    "https://www.wnacg03.ru",
  ];

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
            title: const Text("Domain"),
            trailing: Select(
              width: 180,
              initialValue: !htUrls.contains(appdata.settings[31]) ? 0 :
                htUrls.indexOf(appdata.settings[31]),
              whenChange: (i){
                appdata.settings[31] = htUrls[i];
                appdata.updateSettings();
                HtmangaNetwork().loginFromAppdata();
              },
              values: List.generate(htUrls.length, (index) => htUrls[index].substring(8)),
              inPopUpWidget: popUp,
            ),
          )
        ],
      ),
    );
  }
}