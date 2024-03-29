part of pica_settings;

Widget buildExploreSettings(BuildContext context, bool popUp) {
  return Column(
    children: [
      SettingsTitle("显示".tl),
      NewPageSetting(
        title: "关键词屏蔽".tl,
        onTap: () => showAdaptiveWidget(context,
            BlockingKeywordPage(popUp: MediaQuery.of(context).size.width>600,)),
        icon: const Icon(Icons.block)
      ),
      SelectSetting(
        icon: const Icon(Icons.article_outlined),
        title: "初始页面".tl,
        options: ["我".tl, "收藏".tl, "探索".tl, "分类".tl],
        settingsIndex: 23,
      ),
      NewPageSetting(
          title: "探索页面".tl,
          onTap: () => setExplorePages(context),
          icon:  const Icon(Icons.pages)
      ),
      NewPageSetting(
          title: "分类页面".tl,
          onTap: () => showAdaptiveWidget(App.globalContext!,
              MultiPagesFilter("分类页面".tl, 67, categoryPages())),
          icon:  const Icon(Icons.account_tree)
      ),
      NewPageSetting(
          title: "网络收藏页面".tl,
          onTap: () => showAdaptiveWidget(App.globalContext!,
              MultiPagesFilter("网络收藏页面".tl, 68, networkFavorites())),
          icon: const Icon(Icons.favorite),
      ),
      SelectSetting(
        icon: const Icon(Icons.list),
        title: "漫画列表显示方式".tl,
        options: ["顺序显示".tl, "分页显示".tl],
        settingsIndex: 25,
      ),
      SettingsTitle("工具".tl),
      SwitchSetting(
        title: "检查剪切板中的链接".tl,
        settingsIndex: 61,
        icon: const Icon(Icons.image),
      ),
      SelectSetting(
        title: "默认搜索源".tl,
        settingsIndex: 63,
        options: ["Picacg", "EHentai", "禁漫天堂".tl, "hitomi", "绅士漫画".tl, "nhentai"],
        icon: const Icon(Icons.search),
      ),
      SwitchSetting(
        title: "启用侧边翻页栏".tl,
        icon: const Icon(Icons.border_right),
        settingsIndex: 64,
      ),
      SelectSetting(
        title: "自动添加语言筛选".tl,
        settingsIndex: 69,
        options: ["无".tl, "chinese", "english", "japanese"],
        icon: const Icon(Icons.language),
      ),
      SettingsTitle("漫画块".tl),
      ListTile(
        leading: const Icon(Icons.crop_square),
        title: Text("漫画块显示模式".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[44].split(',').first),
          whenChange: (i) {
            var settings = appdata.settings[44].split(',');
            settings[0] = i.toString();
            if(settings.length == 1){
              settings.add("1.0");
            }
            appdata.settings[44] = settings.join(',');
            appdata.updateSettings();
            MyApp.updater?.call();
          },
          values: ["详细".tl, "简略".tl],
          inPopUpWidget: popUp,
        ),
      ),
      StatefulBuilder(builder: (context, setState){
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: Row(
              children: [
                const SizedBox(width: 16,),
                const Icon(Icons.crop_free),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 12,
                        right: 0,
                        child: Text("漫画块大小".tl, style: const TextStyle(
                            fontSize: 16
                        ),),
                      ),
                      Positioned(
                        left: -8,
                        right: 0,
                        bottom: 0,
                        child: Slider(
                          max: 1.25,
                          min: 0.75,
                          divisions: 10,
                          value: double.parse(appdata.settings[44].split(',').elementAtOrNull(1) ?? "1.00"),
                          overlayColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.transparent),
                          onChangeEnd: (v){
                            appdata.updateSettings();
                          },
                          onChanged: (v) {
                            var settings = appdata.settings[44].split(',');
                            if(settings.length == 1){
                              settings.add(v.toStringAsFixed(2));
                            } else {
                              settings[1] = v.toStringAsFixed(2);
                            }
                            setState((){
                              appdata.settings[44] = settings.join(',');
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Text(appdata.settings[44].split(',').elementAtOrNull(1) ?? "1.00"),
                const SizedBox(width: 32,),
              ],
            ),
          ),
        );
      }),
      SelectSetting(
        title: "漫画块缩略图布局".tl,
        settingsIndex: 66,
        options: ["覆盖".tl, "容纳".tl],
        icon: const Icon(Icons.image),
      ),
      SwitchSetting(
        title: "显示收藏状态".tl,
        settingsIndex: 72,
        icon: const Icon(Icons.bookmark),
      ),
      SwitchSetting(
        title: "显示阅读位置".tl,
        settingsIndex: 73,
        icon: const Icon(Icons.history_toggle_off),
      ),
      StatefulBuilder(builder: (context, setState){
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            height: 64,
            child: Row(
              children: [
                const SizedBox(width: 16,),
                const Icon(Icons.crop_free),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 12,
                        right: 0,
                        child: Text("图片收藏大小".tl, style: const TextStyle(
                            fontSize: 16
                        ),),
                      ),
                      Positioned(
                        left: -8,
                        right: 0,
                        bottom: 0,
                        child: Slider(
                          max: 1.25,
                          min: 0.75,
                          divisions: 10,
                          value: double.parse(appdata.settings[74]),
                          overlayColor: MaterialStateColor.resolveWith(
                                  (states) => Colors.transparent),
                          onChangeEnd: (v){
                            appdata.updateSettings();
                          },
                          onChanged: (v) {
                            setState((){
                              appdata.settings[74] = v.toStringAsFixed(2);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Text(appdata.settings[74]),
                const SizedBox(width: 32,),
              ],
            ),
          ),
        );
      }),
      Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
    ],
  );
}

Map<String, String> categoryPages(){
  return {
    "picacg": "Picacg",
    "ehentai": "ehentai",
    "jm": "禁漫天堂".tl,
    "htmanga": "绅士漫画".tl,
    "nhentai": "nhentai",
    for(var source in ComicSource.sources)
      if(source.categoryData != null)
        source.categoryData!.title: source.categoryData!.title
  };
}

Map<String, String> networkFavorites(){
  return {
    "picacg": "Picacg",
    "ehentai": "ehentai",
    "jm": "禁漫天堂".tl,
    "htmanga": "绅士漫画".tl,
    "nhentai": "nhentai",
    for(var source in ComicSource.sources)
      if(source.favoriteData != null)
        source.key: source.favoriteData!.title
  };
}