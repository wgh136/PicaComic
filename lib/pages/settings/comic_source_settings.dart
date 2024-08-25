part of pica_settings;

class ComicSourceSettings extends StatefulWidget {
  const ComicSourceSettings({super.key});

  @override
  State<ComicSourceSettings> createState() => _ComicSourceSettingsState();

  static void checkCustomComicSourceUpdate([bool showLoading = false]) async {
    if (ComicSource.sources.isEmpty) {
      return;
    }
    var controller = showLoading ? showLoadingDialog(App.globalContext!) : null;
    var dio = logDio();
    var res = await dio.get<String>(
        "https://raw.githubusercontent.com/wgh136/pica_configs/master/index.json");
    if (res.statusCode != 200) {
      showToast(message: "网络错误".tl);
      return;
    }
    var list = jsonDecode(res.data!) as List;
    var versions = <String, String>{};
    for (var source in list) {
      versions[source['key']] = source['version'];
    }
    var shouldUpdate = <String>[];
    for (var source in ComicSource.sources) {
      if (versions.containsKey(source.key) &&
          versions[source.key] != source.version) {
        shouldUpdate.add(source.key);
      }
    }
    controller?.close();
    if (shouldUpdate.isEmpty) {
      return;
    }
    var msg = "";
    for (var key in shouldUpdate) {
      msg += "${ComicSource.find(key)?.name}: v${versions[key]}\n";
    }
    msg = msg.trim();
    showConfirmDialog(App.globalContext!, "有可用更新".tl, msg, () {
      for (var key in shouldUpdate) {
        var source = ComicSource.find(key);
        _ComicSourceSettingsState.update(source!);
      }
    });
  }
}

extension _WidgetExt on Widget {
  Widget withDivider() {
    return Column(
      children: [
        this,
        const Divider(),
      ],
    );
  }
}

class _ComicSourceSettingsState extends State<ComicSourceSettings> {
  var url = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildCard(context),
        const _BuiltInSources(),
        if(appdata.appSettings.isComicSourceEnabled("picacg"))
          const PicacgSettings(false).withDivider(),
        if(appdata.appSettings.isComicSourceEnabled("ehentai"))
          const EhSettings(false).withDivider(),
        if(appdata.appSettings.isComicSourceEnabled("jm"))
          const JmSettings(false).withDivider(),
        if(appdata.appSettings.isComicSourceEnabled("htmanga"))
          const HtSettings(false).withDivider(),
        buildCustomSettings(),
        for (var source in ComicSource.sources.where((e) => !e.isBuiltIn))
          buildCustom(context, source),
        Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
      ],
    );
  }

  Widget buildCustomSettings() {
    return Column(
      children: [
        ListTile(
          title: Text("自定义漫画源".tl),
        ),
        ListTile(
          leading: const Icon(Icons.update_outlined),
          title: Text("检查更新".tl),
          onTap: () => ComicSourceSettings.checkCustomComicSourceUpdate(true),
          trailing: const Icon(Icons.arrow_right),
        ),
        SwitchSetting(
          title: "启动时检查更新".tl,
          icon: const Icon(Icons.security_update),
          settingsIndex: 80,
        )
      ],
    );
  }

  Widget buildCustom(BuildContext context, ComicSource source) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          title: Text(source.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (App.isDesktop)
                Tooltip(
                  message: "Edit",
                  child: IconButton(
                      onPressed: () => edit(source),
                      icon: const Icon(Icons.edit_note)),
                ),
              Tooltip(
                message: "Update",
                child: IconButton(
                    onPressed: () => update(source),
                    icon: const Icon(Icons.update)),
              ),
              Tooltip(
                message: "Delete",
                child: IconButton(
                    onPressed: () => delete(source),
                    icon: const Icon(Icons.delete)),
              ),
            ],
          ),
        ),
        ListTile(
          title: const Text("Version"),
          subtitle: Text(source.version),
        )
      ],
    );
  }

  void delete(ComicSource source) {
    showConfirmDialog(App.globalContext!, "删除".tl, "要删除此漫画源吗?".tl, () {
      var file = File(source.filePath);
      file.delete();
      ComicSource.sources.remove(source);
      _validatePages();
      MyApp.updater?.call();
    });
  }

  void edit(ComicSource source) async {
    try {
      await Process.run("code", [source.filePath], runInShell: true);
      await showDialog(
          context: App.globalContext!,
          builder: (context) => AlertDialog(
                title: const Text("Reload Configs"),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("cancel")),
                  TextButton(
                      onPressed: () async {
                        await ComicSource.reload();
                        MyApp.updater?.call();
                      },
                      child: const Text("continue")),
                ],
              ));
    } catch (e) {
      showToast(message: "Failed to launch vscode");
    }
  }

  static void update(ComicSource source) async {
    ComicSource.sources.remove(source);
    if (!source.url.isURL) {
      showToast(message: "Invalid url config");
    }
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!,
        onCancel: () => cancel = true, barrierDismissible: false);
    try {
      var res = await logDio().get<String>(source.url,
          options: Options(responseType: ResponseType.plain));
      if (cancel) return;
      controller.close();
      await ComicSourceParser().parse(res.data!, source.filePath);
      await File(source.filePath).writeAsString(res.data!);
    } catch (e) {
      if (cancel) return;
      showToast(message: e.toString());
    }
    await ComicSource.reload();
    MyApp.updater?.call();
  }

  Widget buildCard(BuildContext context) {
    return Card.outlined(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("添加漫画源".tl),
              leading: const Icon(Icons.dashboard_customize),
            ),
            TextField(
                    decoration: InputDecoration(
                        hintText: "URL",
                        border: const UnderlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        suffix: IconButton(
                            onPressed: () => handleAddSource(url),
                            icon: const Icon(Icons.check))),
                    onChanged: (value) {
                      url = value;
                    },
                    onSubmitted: handleAddSource)
                .paddingHorizontal(16)
                .paddingBottom(32),
            Row(
              children: [
                TextButton(onPressed: chooseFile, child: Text("选择文件".tl))
                    .paddingLeft(8),
                const Spacer(),
                TextButton(
                    onPressed: () {
                      showPopUpWidget(
                          context, _ComicSourceList(handleAddSource));
                    },
                    child: Text("浏览列表".tl)),
                const Spacer(),
                TextButton(onPressed: help, child: Text("查看帮助".tl))
                    .paddingRight(8),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ).paddingHorizontal(12);
  }

  void chooseFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      extensions: <String>['js'],
    );
    final XFile? file =
        await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;
    try {
      var fileName = file.name;
      // file.readAsString 会导致中文乱码
      var bytes = await file.readAsBytes();
      var content = utf8.decode(bytes);
      await addSource(content, fileName);
    } catch (e) {
      showToast(message: e.toString());
    }
  }

  void help() {
    launchUrlString(
        "https://github.com/wgh136/PicaComic/blob/master/doc/comic_source.md");
  }

  Future<void> handleAddSource(String url) async {
    if (url.isEmpty) {
      return;
    }
    var splits = url.split("/");
    splits.removeWhere((element) => element == "");
    var fileName = splits.last;
    bool cancel = false;
    var controller = showLoadingDialog(App.globalContext!,
        onCancel: () => cancel = true, barrierDismissible: false);
    try {
      var res = await logDio()
          .get<String>(url, options: Options(responseType: ResponseType.plain));
      if (cancel) return;
      controller.close();
      await addSource(res.data!, fileName);
    } catch (e) {
      if (cancel) return;
      showToast(message: e.toString());
    }
  }

  Future<void> addSource(String js, String fileName) async {
    var comicSource = await ComicSourceParser().createAndParse(js, fileName);
    ComicSource.sources.add(comicSource);
    _addAllPagesWithComicSource(comicSource);
    appdata.updateSettings();
    MyApp.updater?.call();
  }
}

class _ComicSourceList extends StatefulWidget {
  const _ComicSourceList(this.onAdd);

  final Future<void> Function(String) onAdd;

  @override
  State<_ComicSourceList> createState() => _ComicSourceListState();
}

class _ComicSourceListState extends State<_ComicSourceList> {
  bool loading = true;
  List? json;

  void load() async {
    var dio = logDio();
    var res = await dio.get<String>(
        "https://raw.githubusercontent.com/wgh136/pica_configs/master/index.json");
    if (res.statusCode != 200) {
      showToast(message: "网络错误".tl);
      return;
    }
    setState(() {
      json = jsonDecode(res.data!);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("漫画源".tl),
        actions: const [
          IconButton(onPressed: App.globalBack, icon: Icon(Icons.close)),
        ],
      ),
      body: buildBody(),
    );
  }

  Widget buildBody() {
    if (loading) {
      load();
      return const Center(child: CircularProgressIndicator());
    } else {
      var currentKey = ComicSource.sources.map((e) => e.key).toList();
      return ListView.builder(
        itemCount: json!.length,
        itemBuilder: (context, index) {
          var key = json![index]["key"];
          var action = currentKey.contains(key)
              ? const Icon(Icons.check)
              : Tooltip(
                  message: "Add",
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      await widget.onAdd(
                          "https://raw.githubusercontent.com/wgh136/pica_configs/master/${json![index]["fileName"]}");
                      setState(() {});
                    },
                  ),
                );

          return ListTile(
            title: Text(json![index]["name"]),
            subtitle: Text(json![index]["version"]),
            trailing: action,
          );
        },
      );
    }
  }
}

class _BuiltInSources extends StatefulWidget {
  const _BuiltInSources();

  @override
  State<_BuiltInSources> createState() => _BuiltInSourcesState();
}

class _BuiltInSourcesState extends State<_BuiltInSources> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        ListTile(
          title: Text("内置漫画源".tl),
        ),
        for(int index = 0; index < builtInSources.length; index++)
          buildTile(index),
        const Divider(),
      ],
    );
  }

  bool isLoading = false;

  Widget buildTile(int index) {
    var key = builtInSources[index];
    return ListTile(
      title: Text(
          ComicSource.builtIn.firstWhere((e) => e.key == key).name),
      trailing: Switch(
        value: appdata.appSettings.isComicSourceEnabled(key),
        onChanged: (v) async {
          if (isLoading) return;
          isLoading = true;
          appdata.appSettings.setComicSourceEnabled(key, v);
          await appdata.updateSettings();
          if(!v) {
            ComicSource.sources.removeWhere((e) => e.key == key);
            _validatePages();
          } else {
            var source = ComicSource.builtIn.firstWhere((e) => e.key == key);
            ComicSource.sources.add(source);
            source.loadData();
            _addAllPagesWithComicSource(source);
          }
          isLoading = false;
          if (mounted) {
            setState(() {});
            context.findAncestorStateOfType<_ComicSourceSettingsState>()
                ?.setState(() {});
          }
        },
      ),
    );
  }
}

void _validatePages() {
  var explorePages = appdata.appSettings.explorePages;
  var categoryPages = appdata.appSettings.categoryPages;
  var networkFavorites = appdata.appSettings.networkFavorites;

  var totalExplorePages = ComicSource.sources
      .map((e) => e.explorePages.map((e) => e.title))
      .expand((element) => element)
      .toList();
  var totalCategoryPages = ComicSource.sources
      .map((e) => e.categoryData?.key)
      .where((element) => element != null)
      .map((e) => e!)
      .toList();
  var totalNetworkFavorites = ComicSource.sources
      .map((e) => e.favoriteData?.key)
      .where((element) => element != null)
      .map((e) => e!)
      .toList();

  for (var page in List.from(explorePages)) {
    if (!totalExplorePages.contains(page)) {
      explorePages.remove(page);
    }
  }
  for (var page in List.from(categoryPages)) {
    if (!totalCategoryPages.contains(page)) {
      categoryPages.remove(page);
    }
  }
  for (var page in List.from(networkFavorites)) {
    if (!totalNetworkFavorites.contains(page)) {
      networkFavorites.remove(page);
    }
  }

  appdata.appSettings.explorePages = explorePages;
  appdata.appSettings.categoryPages = categoryPages;
  appdata.appSettings.networkFavorites = networkFavorites;

  appdata.updateSettings();
}

void _addAllPagesWithComicSource(ComicSource source) {
  var explorePages = appdata.appSettings.explorePages;
  var categoryPages = appdata.appSettings.categoryPages;
  var networkFavorites = appdata.appSettings.networkFavorites;

  if (source.explorePages.isNotEmpty) {
    for (var page in source.explorePages) {
      if (!explorePages.contains(page.title)) {
        explorePages.add(page.title);
      }
    }
  }
  if (source.categoryData != null &&
      !categoryPages.contains(source.categoryData!.key)) {
    categoryPages.add(source.categoryData!.key);
  }
  if (source.favoriteData != null &&
      !networkFavorites.contains(source.favoriteData!.key)) {
    networkFavorites.add(source.favoriteData!.key);
  }

  appdata.appSettings.explorePages = explorePages.toSet().toList();
  appdata.appSettings.categoryPages = categoryPages.toSet().toList();
  appdata.appSettings.networkFavorites = networkFavorites.toSet().toList();

  appdata.updateSettings();
}