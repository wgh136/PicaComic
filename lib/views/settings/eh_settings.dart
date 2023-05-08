import 'package:flutter/material.dart';
import 'package:pica_comic/eh_network/eh_main_network.dart';

import '../../base.dart';

class EhDomainSetting extends StatefulWidget {
  const EhDomainSetting({Key? key}) : super(key: key);

  @override
  State<EhDomainSetting> createState() => _EhDomainSettingState();
}

class _EhDomainSettingState extends State<EhDomainSetting> {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("设置画廊站点"),
      children: [
        ListTile(
          title: const Text("e-hentai.org"),
          onTap: (){
            setState(() {
              appdata.settings[20] = "0";
            });
            appdata.updateSettings();
            EhNetwork().updateUrl();
          },
          trailing: Radio<String>(
            value: "0",
            groupValue: appdata.settings[20],
            onChanged: (s){
              setState(() {
                appdata.settings[20] = s!;
              });
              appdata.updateSettings();
              EhNetwork().updateUrl();
            },
          ),
        ),
        ListTile(
          title: const Text("exhentai.org"),
          onTap: (){
            setState(() {
              appdata.settings[20] = "1";
            });
            appdata.updateSettings();
            EhNetwork().updateUrl();
          },
          trailing: Radio<String>(
            value: "1",
            groupValue: appdata.settings[20],
            onChanged: (s){
              setState(() {
                appdata.settings[20] = s!;
              });
              appdata.updateSettings();
              EhNetwork().updateUrl();
            },
          ),
        ),
      ],
    );
  }
}

void setEhDomain(BuildContext context){
  showDialog(context: context, builder: (context){
    return const EhDomainSetting();
  });
}