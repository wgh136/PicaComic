import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/settings/app_settings.dart';
import 'package:pica_comic/views/settings/blocking_keyword_page.dart';
import 'package:pica_comic/views/widgets/select.dart';

Widget buildExploreSettings(BuildContext context, bool popUp) {
  return Column(
    children: [
      ListTile(
        leading:
            const Icon(Icons.block),
        title: Text("关键词屏蔽".tl),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BlockingKeywordPage(
                  popUp: popUp,
                ))),
        trailing: const Icon(Icons.arrow_right),
      ),
      ListTile(
        leading: const Icon(Icons.network_ping),
        title: Text("设置代理".tl),
        trailing: const Icon(
          Icons.arrow_right,
        ),
        onTap: () {
          setProxy(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.article_outlined),
        title: Text("初始页面".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[23]),
          whenChange: (i) {
            appdata.settings[23] = i.toString();
            appdata.updateSettings();
          },
          values: ["我".tl, "探索".tl, "分类".tl, "排行榜".tl],
          inPopUpWidget: popUp,
        ),
      ),
      ListTile(
        leading:
            const Icon(Icons.source),
        title: Text("漫画源(非探索页面)".tl),
        trailing: const Icon(Icons.arrow_right),
        onTap: () => setComicSource(context),
      ),
      ListTile(
        leading:
            const Icon(Icons.pages),
        title: Text("显示的探索页面".tl),
        trailing: const Icon(Icons.arrow_right),
        onTap: () => setExplorePages(context),
      ),
      ListTile(
        leading:
            const Icon(Icons.list),
        title: Text("漫画列表显示方式".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[25]),
          whenChange: (i) {
            appdata.settings[25] = i.toString();
            appdata.updateSettings();
          },
          values: ["顺序显示".tl, "分页显示".tl],
          inPopUpWidget: popUp,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.file_download_outlined),
        title: Text("已下载的漫画排序方式".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[26][0]),
          whenChange: (i) {
            appdata.settings[26].setValueAt(i.toString(), 0);
            appdata.updateSettings();
          },
          values: ["时间".tl, "漫画名".tl, "作者名".tl, "大小".tl],
          inPopUpWidget: popUp,
        ),
      ),
      ListTile(
        leading: const Icon(Icons.crop_square),
        title: Text("漫画块显示模式".tl),
        subtitle: Text("需要重新加载页面".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[44]),
          whenChange: (i) {
            appdata.settings[44] = i.toString();
            appdata.updateSettings();
          },
          values: ["详细".tl, "简略".tl, "最小".tl, "详细(大)".tl],
          inPopUpWidget: popUp,
        ),
      ),
      FutureBuilder(future: LocalFavoritesManager().readData(), builder: (context, data){
        if(LocalFavoritesManager().folderNames == null){
          return const SizedBox();
        } else {
          return ListTile(
            leading: const Icon(Icons.book),
            title: Text("默认收藏夹".tl),
            subtitle: Text("用于快速收藏".tl),
            trailing: Select(
              initialValue: LocalFavoritesManager().folderNames!.indexOf(appdata.settings[51]),
              whenChange: (i) {
                appdata.settings[51] = LocalFavoritesManager().folderNames![i];
                appdata.updateSettings();
              },
              values: LocalFavoritesManager().folderNames!,
              inPopUpWidget: popUp,
            ),
          );
        }
      }),
    ],
  );
}
