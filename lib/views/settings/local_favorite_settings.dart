part of pica_settings;

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
          title: Text("快速收藏".tl),
          subtitle: Text("长按收藏按钮执行快速收藏".tl),
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
        SelectSetting(
          icon: const Icon(Icons.bookmark_add),
          title: "新收藏添加至".tl,
          options: ["最后".tl, "最前".tl],
          settingsIndex: 53,
        ),
        SelectSetting(
          icon: const Icon(Icons.move_up),
          title: "阅读后移动本地收藏至".tl,
          options: ["无操作".tl, "最后".tl, "最前".tl],
          settingsIndex: 54,
        ),
        SelectSetting(
          icon: const Icon(Icons.touch_app),
          title: "点击漫画时".tl,
          options: ["查看信息".tl, "阅读".tl],
          settingsIndex: 60,
        ),
        SwitchSetting(
          title: "显示收藏数量".tl,
          settingsIndex: 65,
          icon: const Icon(Icons.library_books_rounded),
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
