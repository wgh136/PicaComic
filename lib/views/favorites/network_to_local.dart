import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/favorites.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/net_fav_to_local.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../../base.dart';
import '../../network/base_comic.dart';
import '../../network/res.dart';

class _ChooseNetworkFolderWidget extends StatefulWidget {
  const _ChooseNetworkFolderWidget();

  @override
  State<_ChooseNetworkFolderWidget> createState() =>
      _ChooseNetworkFolderWidgetState();
}

class LoadComicClass {
  NetToLocalEhPageData data = NetToLocalEhPageData();

  Future<Res<List<BaseComic>>> loadComic(
      FavoriteData fData, int i, String folder) async {
    if (fData.key == "ehentai") {
      if (data.galleries == null) {
        Res<Galleries> res = await EhNetwork().getGalleries(
            "${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folder&inline_set=dm_l",
            favoritePage: true);
        if (res.error) {
          return Res(null, errorMessage: res.errorMessage);
        } else {
          data.galleries = res.data;
          data.comics[1] = [];
          data.comics[1]!.addAll(data.galleries!.galleries);
          data.galleries!.galleries.clear();
        }
      }
      if (data.comics[i] != null) {
        return Res(data.comics[i]!);
      } else {
        while (data.comics[i] == null) {
          data.page++;
          if (!await EhNetwork().getNextPageGalleries(data.galleries!)) {
            return Res(null, errorMessage: "网络错误".tl);
          }
          data.comics[data.page] = [];
          data.comics[data.page]!.addAll(data.galleries!.galleries);
          data.galleries!.galleries.clear();
        }
        return Res(data.comics[i]);
      }
    }
    return fData.loadComic(i, folder);
  }
}

class _ChooseNetworkFolderWidgetState
    extends State<_ChooseNetworkFolderWidget> {
  late final List<FavoriteData> _folders;

  late List<bool> isExpanded;

  String? selected;
  bool agreeSync = false;

  Map<String, Map<String, String>> multiFolderData = {
    "ehentai": Map.fromIterables(
        List.generate(10, (index) => index.toString()), EhNetwork().folderNames)
  };

  @override
  void initState() {
    var folders = <FavoriteData>[];
    for (var key in appdata.settings[68].split(',')) {
      folders.add(getFavoriteData(key));
    }
    _folders = folders;
    isExpanded = _folders.map((e) => false).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("选择收藏夹".tl),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
                onPressed: () => App.globalBack(),
                icon: const Icon(Icons.close)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ExpansionPanelList(
                materialGapSize: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                expansionCallback: (i, value) =>
                    setState(() => isExpanded[i] = value),
                children: _folders.map((e) => buildItem(e)).toList(),
              ),
            ),
          ),
          const Divider(
            height: 1,
          ),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                Checkbox(
                    value: agreeSync,
                    onChanged: (b) {
                      setState(() {
                        agreeSync = b ?? false;
                      });
                    }),
                Text("支持下拉更新".tl),
                const Spacer(),
                FilledButton(onPressed: onConfirm, child: Text("继续".tl)),
                const SizedBox(
                  width: 24,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  ExpansionPanel buildItem(FavoriteData data) {
    return ExpansionPanel(
        headerBuilder: (context, expand) {
          return ListTile(
            title: Text(data.title),
          );
        },
        isExpanded: isExpanded[_folders.indexOf(data)],
        body: buildBody(data),
        canTapOnHeader: true);
  }

  Widget buildTile(String key, String title) {
    return RadioListTile<String?>(
        title: Text(title),
        value: key,
        groupValue: selected,
        onChanged: (newValue) {
          setState(() {
            selected = newValue;
          });
        });
  }

  Widget buildBody(FavoriteData data) {
    if (!data.multiFolder) {
      return buildTile(data.key, data.title);
    } else {
      return StatefulBuilder(builder: (context, updater) {
        if (multiFolderData[data.key] == null) {
          if (isExpanded[_folders.indexOf(data)]) {
            data.loadFolders!().then((value) {
              if (value.error) {
                showMessage(App.globalContext, "网络错误".tl);
              } else {
                updater(() {
                  multiFolderData[data.key] = value.data;
                });
              }
            });
          }
          return const SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: multiFolderData[data.key]!
                .entries
                .map((e) => buildTile("${data.key}:${e.key}", e.value))
                .toList(),
          );
        }
      });
    }
  }

  void onConfirm() {
    var key = selected!.split(":").first;
    var folderId = selected!.split(":").last;
    var data = _folders.firstWhere((element) => element.key == key);
    String name;
    if (!data.multiFolder) {
      name = data.title;
    } else {
      name = multiFolderData[data.key]![folderId]!;
      if (data.key == "ehentai") {
        name = name.substring(0, name.lastIndexOf("("));
      }
    }
    App.globalBack();
    final loadComicObj = LoadComicClass();
    startConvert<BaseComic>(
        (page) => loadComicObj.loadComic(data, page, folderId),
        null,
        App.globalContext!,
        name,
        (comic) => FavoriteItem.fromBaseComic(comic),
        data.key,
        agreeSync,
        {"folderId": folderId});
  }
}

void networkToLocal() {
  showPopUpWidget(App.globalContext!, const _ChooseNetworkFolderWidget());
}

class NetToLocalEhPageData {
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}
