import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/settings/app_settings.dart';
import 'package:pica_comic/views/settings/blocking_keyword_page.dart';
import 'package:pica_comic/views/widgets/select.dart';

Widget buildExploreSettings(BuildContext context, bool popUp) {
  return Card(
    elevation: 0,
    child: Column(
      children: [
        ListTile(
          title: Text("浏览".tl),
        ),
        ListTile(
          leading:
              Icon(Icons.block, color: Theme.of(context).colorScheme.secondary),
          title: Text("关键词屏蔽".tl),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => BlockingKeywordPage(
                    popUp: popUp,
                  ))),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: Icon(Icons.network_ping,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("设置代理".tl),
          trailing: const Icon(
            Icons.arrow_right,
          ),
          onTap: () {
            setProxy(context);
          },
        ),
        ListTile(
          leading: Icon(Icons.article_outlined,
              color: Theme.of(context).colorScheme.secondary),
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
          leading: Icon(Icons.source,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("漫画源(非探索页面)".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => setComicSource(context),
        ),
        ListTile(
          leading:
              Icon(Icons.pages, color: Theme.of(context).colorScheme.secondary),
          title: Text("显示的探索页面".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => setExplorePages(context),
        ),
        ListTile(
          leading:
              Icon(Icons.list, color: Theme.of(context).colorScheme.secondary),
          title: Text("漫画列表显示方式".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[25]),
            whenChange: (i) {
              appdata.settings[26] = appdata.settings[25] = i.toString();
              appdata.updateSettings();
            },
            values: ["顺序显示".tl, "分页显示".tl],
            inPopUpWidget: popUp,
          ),
        ),
        ListTile(
          leading: Icon(Icons.file_download_outlined,
              color: Theme.of(context).colorScheme.secondary),
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
          leading: Icon(Icons.crop_square,
              color: Theme.of(context).colorScheme.secondary),
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
      ],
    ),
  );
}
