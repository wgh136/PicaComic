part of pica_settings;

void findUpdate(BuildContext context) {
  context.showMessage(message: "正在检查更新".tl);
  checkUpdate().then((b) {
    if (!context.mounted) return;
    if (b == null) {
      context.showMessage(message: "网络错误".tl);
    } else if (b) {
      getUpdatesInfo().then((s) {
        if (!context.mounted) return;
        if (s != null) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("有可用更新".tl),
                  content: Text(s),
                  actions: [
                    TextButton(
                        onPressed: () => App.globalBack(),
                        child: Text("取消".tl)),
                    TextButton(
                        onPressed: () {
                          getDownloadUrl().then((s) {
                            launchUrlString(s,
                                mode: LaunchMode.externalApplication);
                          });
                        },
                        child: Text("下载".tl))
                  ],
                );
              });
        } else {
          context.showMessage(message: "网络错误".tl);
        }
      });
    } else {
      context.showMessage(message: "已是最新版本".tl);
    }
  });
}

class ProxyController extends StateController {
  bool value = appdata.settings[8] == "0";
  late var controller =
      TextEditingController(text: value ? "" : appdata.settings[8]);
}

void setProxy(BuildContext context) {
  showDialog(
      context: context,
      builder: (dialogContext) {
        return StateBuilder(
            init: ProxyController(),
            builder: (controller) {
              return SimpleDialog(
                title: Text("设置代理".tl),
                children: [
                  const SizedBox(
                    width: 400,
                  ),
                  ListTile(
                    title: Text("使用系统代理".tl),
                    trailing: Switch(
                      value: controller.value,
                      onChanged: (value) {
                        if (value == true) {
                          controller.controller.text = "";
                        }
                        controller.value = !controller.value;
                        controller.update();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: TextField(
                      readOnly: controller.value,
                      controller: controller.controller,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: controller.value
                              ? "使用系统代理时无法手动设置".tl
                              : "设置代理, 例如127.0.0.1:7890".tl),
                    ),
                  ),
                  if (!controller.value)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 15, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                          ),
                          Text("  ${"留空表示禁用网络代理".tl}")
                        ],
                      ),
                    ),
                  Center(
                    child: FilledButton(
                        onPressed: () {
                          if (controller.value) {
                            appdata.settings[8] = "0";
                            appdata.writeData();
                            setNetworkProxy();
                            App.globalBack();
                          } else {
                            appdata.settings[8] = controller.controller.text;
                            appdata.writeData();
                            setNetworkProxy();
                            App.globalBack();
                          }
                        },
                        child: Text("确认".tl)),
                  )
                ],
              );
            });
      });
}

void setDownloadFolder() async {
  if (DownloadManager().downloading.isNotEmpty) {
    showToast(message: "请在下载任务完成后进行操作".tl);
    return;
  }

  if (App.isAndroid) {
    var directories = await getExternalStorageDirectories();
    var paths = List<String>.generate(
        directories?.length ?? 0, (index) => directories?[index].path ?? "");
    var havePermission = await const MethodChannel("pica_comic/settings")
        .invokeMethod("files_check");
    showDialog(
        context: App.globalContext!,
        builder: (context) => SetDownloadFolderDialog(
              paths: paths,
              haveManageFilesPermission: havePermission,
            ));
  } else {
    showDialog(
        context: App.globalContext!,
        builder: (context) => const SetDownloadFolderDialog());
  }
}

class SetDownloadFolderDialog extends StatefulWidget {
  const SetDownloadFolderDialog(
      {this.paths, this.haveManageFilesPermission = false, Key? key})
      : super(key: key);
  final List<String>? paths;
  final bool haveManageFilesPermission;

  @override
  State<SetDownloadFolderDialog> createState() =>
      _SetDownloadFolderDialogState();
}

class _SetDownloadFolderDialogState extends State<SetDownloadFolderDialog> {
  final controller = TextEditingController();
  String current = appdata.settings[22];
  bool transform = true;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("设置下载目录".tl),
      children: [
        if (App.isDesktop || widget.haveManageFilesPermission)
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "路径".tl,
                        hintText: "为空表示使用App数据目录".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CheckboxListTile(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b!;
                    }),
                    title: Text("转移数据".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                Center(
                  child: FilledButton(
                    onPressed: () async {
                      if (controller.text == appdata.settings[22]) return;
                      var directory = Directory(controller.text);
                      if (directory.existsSync() || controller.text == "") {
                        var oldPath = appdata.settings[22];
                        appdata.settings[22] = controller.text;
                        if (transform) {
                          showToast(message: "正在复制文件".tl);
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                        }
                        var res = await downloadManager
                            .updatePath(controller.text, transform: transform);
                        if (res == "ok") {
                          hideAllMessages();
                          if (context.mounted) {
                            context.pop();
                          }
                          showToast(message: "更新成功".tl);
                          appdata.updateSettings();
                        } else {
                          appdata.settings[22] = oldPath;
                          showToast(message: res);
                        }
                      } else {
                        showToast(message: "目录不存在".tl);
                      }
                    },
                    child: Text("提交".tl),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text("${"现在的路径为".tl}: ${DownloadManager().path}"),
                )
              ],
            ),
          )
        else
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                    title: Text("App数据目录".tl),
                    value: "",
                    groupValue: current,
                    onChanged: (value) => setState(() {
                          current = value!;
                        })),
                for (int i = 0; i < widget.paths!.length; i++)
                  RadioListTile<String>(
                      title: Text(widget.paths![i]),
                      value: widget.paths![i],
                      groupValue: current,
                      onChanged: (value) => setState(() {
                            current = value!;
                          })),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ListTile(
                    title: Text("允许储存权限".tl),
                    subtitle: Text("需要储存权限以选取任意目录".tl),
                    onTap: () {
                      const MethodChannel("pica_comic/settings")
                          .invokeMethod("files");
                      App.globalBack();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CheckboxListTile(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b!;
                    }),
                    title: Text("转移数据".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 2,
                      ),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Center(
                    child: FilledButton(
                      child: const Text("确认"),
                      onPressed: () async {
                        if (appdata.settings[22] != current) {
                          var oldPath = appdata.settings[22];
                          appdata.settings[22] = current;
                          if (transform) {
                            showToast(message: "正在复制文件".tl);
                            await Future.delayed(
                                const Duration(milliseconds: 200));
                          }
                          var res = await downloadManager.updatePath(current,
                              transform: transform);
                          if (res == "ok") {
                            App.globalBack();
                            showToast(message: "更新成功".tl);
                            appdata.updateSettings();
                          } else {
                            appdata.settings[22] = oldPath;
                            showToast(message: res);
                          }
                        } else {
                          App.globalBack();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}

void setExplorePages(BuildContext context) {
  showPopUpWidget(App.globalContext!, const SetExplorePages());
}

class SetExplorePages extends StatefulWidget {
  const SetExplorePages({Key? key}) : super(key: key);

  @override
  State<SetExplorePages> createState() => _SetExplorePagesState();
}

class _SetExplorePagesState extends State<SetExplorePages> {
  @override
  void dispose() {
    appdata.updateSettings();
    Future.microtask(() {
      MyApp.updater?.call();
    });
    super.dispose();
  }

  Widget buildItem(String i) {
    Widget removeButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
          onPressed: () {
            setState(() {
              var config = appdata.appSettings.explorePages;
              config.remove(i);
              appdata.appSettings.explorePages = config;
            });
          },
          icon: const Icon(Icons.delete)),
    );

    return ListTile(
      title: Text(i.tl),
      key: Key(i),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          removeButton,
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }

  Widget buildNotShowPageSelector(String i, BuildContext context) {
    var widget = ListTile(title: Text(i.tl), key: Key(i));
    return InkWell(
      child: widget,
      onTap: () {
        App.back(context);
        setState(() {
          appdata.appSettings.explorePages = appdata.appSettings.explorePages
            ..add(i);
        });
      },
    );
  }

  var reorderWidgetKey = UniqueKey();
  var scrollController = ScrollController();
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var notShowPages = <String>[];
    var allPages = <String>[];
    for (var source in ComicSource.sources) {
      for (var page in source.explorePages) {
        allPages.add(page.title);
      }
    }
    for (var i in allPages) {
      if (!appdata.appSettings.explorePages.contains(i)) {
        notShowPages.add(i);
      }
    }

    var tiles =
        appdata.appSettings.explorePages.map((e) => buildItem(e)).toList();

    var view = ReorderableBuilder(
      key: reorderWidgetKey,
      scrollController: scrollController,
      longPressDelay: App.isDesktop
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 500),
      dragChildBoxDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
              spreadRadius: 2)
        ],
      ),
      onReorder: (reorderFunc) {
        setState(() {
          appdata.appSettings.explorePages =
              List.from(reorderFunc(appdata.appSettings.explorePages));
        });
      },
      children: tiles,
      builder: (children) {
        return GridView(
          key: _key,
          controller: scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 48,
          ),
          children: children,
        );
      },
    );
    return PopUpWidgetScaffold(
      title: "探索页面".tl,
      tailing: [
        if (notShowPages.isNotEmpty)
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text("Add"),
                    children: notShowPages
                        .map((e) => buildNotShowPageSelector(e, context))
                        .toList(),
                  );
                },
              );
            },
            icon: const Icon(Icons.add),
          )
      ],
      body: view,
    );
  }
}

void clearUserData(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("警告".tl),
            content: Text("此操作无法撤销, 是否继续".tl),
            actions: [
              TextButton(
                  onPressed: () => App.globalBack(), child: Text("取消".tl)),
              TextButton(
                  onPressed: () async {
                    await clearAppdata();
                    App.offAll(() => const WelcomePage());
                    MyApp.updater?.call();
                  },
                  child: Text("继续".tl)),
            ],
          ));
}

void exportDataSetting(BuildContext context) {
  void export(bool includeDownloads) async {
    var dialog = showLoadingDialog(context, allowCancel: false);
    var res = await runExportData(includeDownloads);
    if (context.mounted) {
      if (res) {
        dialog.close();
        showToast(message: "成功导出".tl);
      } else {
        dialog.close();
        showToast(message: "导出失败".tl);
      }
    }
  }

  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("导出用户数据".tl),
            content: Text("将导出设置, 账号, 历史记录, 下载内容, 本地收藏等数据".tl),
            actions: [
              TextButton(
                  onPressed: () => App.globalBack(), child: Text("取消".tl)),
              TextButton(
                  onPressed: () {
                    App.globalBack();
                    export(false);
                  },
                  child: Text("导出不含下载的数据".tl)),
              TextButton(
                  onPressed: () {
                    App.globalBack();
                    export(true);
                  },
                  child: Text("导出所有数据".tl))
            ],
          ));
}

void importDataSetting(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text("导入用户数据".tl),
            content: Text("${"将导入设置, 账号, 历史记录, 下载内容, 本地收藏等数据, 现在的所有数据将会被覆盖".tl}"
                "\n${"如果导入的数据中包含下载数据, 则当前的下载数据也将被覆盖".tl}"),
            actions: [
              TextButton(
                  onPressed: () => App.globalBack(), child: Text("取消".tl)),
              TextButton(
                  onPressed: () {
                    App.globalBack();
                    var dialog = showLoadingDialog(context, allowCancel: false);
                    importData().then((v) {
                      dialog.close();
                      if (v) {
                        showToast(message: "成功导入".tl);
                      } else {
                        showToast(message: "导入失败".tl);
                      }
                    });
                  },
                  child: Text("继续".tl))
            ],
          ));
}

void syncDataSettings(BuildContext context) {
  var configs = ["", "", "", ""];
  if (appdata.settings[45] != "") {
    configs = appdata.settings[45].split(';');
  }
  String url = configs[0];
  String username = configs[1];
  String pwd = configs[2];
  String path = configs[3];
  int value = 0;
  showDialog(
    context: context,
    useSafeArea: false,
    builder: (context) => ContentDialog(
      title: "Webdav",
      content: Column(
        children: [
          TextField(
              onChanged: (s) => url = s,
              controller: TextEditingController(text: url),
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text("URL"),
                  hintText: "https://example.com:4433/webdav")),
          const SizedBox(
            height: 8,
          ),
          TextField(
              onChanged: (s) => username = s,
              controller: TextEditingController(text: username),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: Text("用户名".tl),
              )),
          const SizedBox(
            height: 8,
          ),
          TextField(
              onChanged: (s) => pwd = s,
              controller: TextEditingController(text: pwd),
              obscureText: true,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                label: Text("密码".tl),
              )),
          const SizedBox(
            height: 8,
          ),
          TextField(
              onChanged: (s) => path = s,
              controller: TextEditingController(text: path),
              decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text("储存路径".tl),
                  hintText: "请确保路径存在".tl)),
          const SizedBox(
            height: 8,
          ),
          StatefulBuilder(builder: (context, stateSetter) {
            return Row(
              children: [
                Text("立即执行:".tl),
                Radio<int>(
                    value: 0,
                    groupValue: value,
                    onChanged: (i) => stateSetter(() => value = 0)),
                Text("上传数据".tl),
                Radio<int>(
                    value: 1,
                    groupValue: value,
                    onChanged: (i) => stateSetter(() => value = 1)),
                Text("下载数据".tl),
              ],
            );
          }),
          const SizedBox(
            height: 8,
          ),
          Center(
            child: FilledButton(
              child: Text("提交".tl),
              onPressed: () async {
                if (url.isEmpty) {
                  appdata.settings[45] = "$url;$username;$pwd;$path";
                  appdata.updateSettings();
                  App.globalBack();
                  return;
                }
                var dialog = showLoadingDialog(context,
                    allowCancel: false, barrierDismissible: false);
                var res = value == 0
                    ? await Webdav.uploadData("$url;$username;$pwd;$path")
                    : await Webdav.downloadData("$url;$username;$pwd;$path");
                if (!res) {
                  dialog.close();
                  showToast(message: "Failed to sync data");
                } else {
                  appdata.settings[45] = "$url;$username;$pwd;$path";
                  appdata.updateSettings();
                  dialog.close();
                  App.globalBack();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                ),
                const SizedBox(
                  width: 4,
                ),
                if (configs.length == 4)
                  Text("将URL留空以禁用同步".tl)
                else
                  Text("已禁用".tl)
              ],
            ),
          )
        ],
      ).paddingHorizontal(12),
    ),
  );
}

void setCacheLimit() {
  int size = appdata.appSettings.cacheLimit;
  showDialog(
    context: App.globalContext!,
    useSafeArea: false,
    builder: (context) => ContentDialog(
      title: "设置缓存限制".tl,
      content: TextField(
        controller: TextEditingController(text: size.toString()),
        keyboardType: TextInputType.number,
        onChanged: (s) {
          size = int.tryParse(s) ?? 500;
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffix: Text("MB"),
        ),
      ).paddingHorizontal(16),
      actions: [
        Button.filled(
            child: Text("确认".tl),
            onPressed: () {
              appdata.appSettings.cacheLimit = size;
              appdata.writeData();
              CacheManager().setLimitSize(size);
              App.globalBack();
            }),
      ],
    ),
  );
}
