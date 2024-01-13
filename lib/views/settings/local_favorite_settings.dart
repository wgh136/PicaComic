import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../base.dart';
import '../../foundation/local_favorites.dart';
import '../widgets/select.dart';

class LocalFavoritesSettings extends StatefulWidget {
  const LocalFavoritesSettings({super.key});

  @override
  State<LocalFavoritesSettings> createState() => _LocalFavoritesSettingsState();
}

class _LocalFavoritesSettingsState extends State<LocalFavoritesSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.book),
          title: Text("默认收藏夹".tl),
          trailing: Select(
            initialValue: LocalFavoritesManager()
                .folderNames
                .indexOf(appdata.settings[51]),
            whenChange: (i) {
              appdata.settings[51] =
              LocalFavoritesManager().folderNames[i];
              appdata.updateSettings();
            },
            values: LocalFavoritesManager().folderNames,
            inPopUpWidget: false,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_add),
          title: Text("新收藏添加至".tl),
          trailing: Select(
            values: ["最后".tl, "最前".tl],
            initialValue: int.parse(appdata.settings[53]),
            whenChange: (i) {
              appdata.settings[53] = i.toString();
              appdata.updateSettings();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.move_up),
          title: Text("阅读后移动本地收藏至".tl),
          trailing: Select(
            values: ["无操作".tl, "最后".tl, "最前".tl],
            initialValue: int.parse(appdata.settings[54]),
            whenChange: (i) {
              appdata.settings[54] = i.toString();
              appdata.updateSettings();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.touch_app),
          title: Text("点击时的操作".tl),
          trailing: Select(
            values: ["查看信息".tl, "阅读".tl],
            initialValue: int.parse(appdata.settings[60]),
            whenChange: (i) {
              appdata.settings[60] = i.toString();
              appdata.updateSettings();
            },
          ),
        ),
        ListTile(
          leading:
          const Icon(Icons.library_books_rounded),
          title: Text("显示本地收藏的数量".tl),
          trailing: Switch(
            value: appdata.settings[65] == "1",
            onChanged: (b){
              setState(() {
                appdata.settings[65] = b?"1":"0";
              });
              appdata.updateSettings();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text("下拉更新拉取页数".tl),
          trailing: Select(
            initialValue: ["1", "2", "3", "4", "5", "10", "99"]
                .indexOf(appdata.settings[71]),
            values: const ["1", "2", "3", "4", "5", "10", "99"],
            whenChange: (i) {
              appdata.settings[71] = ["1", "2", "3", "4", "5", "10", "99"][i];
              appdata.updateSettings();
            },
            width: 140,
          ),
        ),
        Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
      ],
    );
  }
}
