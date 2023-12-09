import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
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
        title: Text("探索页面".tl),
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
      StatefulBuilder(builder: (context, setState) => ListTile(
        leading: const Icon(Icons.image),
        title: Text("检查剪切板中的链接".tl),
        trailing: Switch(
          value: appdata.settings[61] == "1",
          onChanged: (b){
            setState(() {
              appdata.settings[61] = b?"1":"0";
            });
            appdata.updateSettings();
          },
        ),
      ),),
      ListTile(
        leading:
        const Icon(Icons.build_circle),
        title: Text("漫画信息页面工具栏".tl),
        trailing: const Icon(Icons.arrow_right),
        onTap: () => setTools(context),
      ),
    ],
  );
}


void setTools(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("设置工具栏".tl),
          children: const [
            SizedBox(
              width: 400,
            ),
            ComicToolsSetting(),
          ],
        );
      });
}

class ComicToolsSetting extends StatefulWidget {
  const ComicToolsSetting({Key? key}) : super(key: key);

  @override
  State<ComicToolsSetting> createState() => _ComicToolsSettingState();
}

class _ComicToolsSettingState extends State<ComicToolsSetting> {
  @override
  void dispose() {
    appdata.updateSettings();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ["快速收藏".tl, "复制标题".tl, "复制链接".tl, "分享".tl, "搜索相似画廊".tl];
    return SizedBox(
      child: Column(
        children: [
          for (int i = 0; i < titles.length; i++)
            CheckboxListTile(
              value: appdata.settings[62][i] == "1",
              onChanged: (b) {
                setState(() {
                  if (b!) {
                    appdata.settings[62] = appdata.settings[62].replaceRange(i, i + 1, '1');
                  } else {
                    appdata.settings[62] = appdata.settings[62].replaceRange(i, i + 1, '0');
                  }
                });
              },
              title: Text(titles[i]),
            ),
        ],
      ),
    );
  }
}