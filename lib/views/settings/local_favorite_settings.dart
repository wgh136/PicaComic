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
          subtitle: Text("用于快速收藏".tl),
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
      ],
    );
  }
}
