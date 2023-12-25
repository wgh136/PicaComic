import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/main.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/settings/app_settings.dart';
import 'package:pica_comic/views/settings/blocking_keyword_page.dart';
import 'package:pica_comic/views/widgets/select.dart';

Widget buildExploreSettings(BuildContext context, bool popUp) {
  var comicTileSettings = appdata.settings[44].split(',');
  if(comicTileSettings[0] == "2"){
    comicTileSettings[0] = "1";
  } else if(comicTileSettings[0] == "3"){
    comicTileSettings[0] = "0";
  }
  appdata.settings[44] = comicTileSettings.join(',');
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
          values: ["我".tl, "收藏".tl, "探索".tl, "分类".tl],
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
      ListTile(
        leading:
        const Icon(Icons.search),
        title: Text("默认搜索源".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[63]),
          whenChange: (i) {
            appdata.settings[63] = i.toString();
            appdata.updateSettings();
          },
          values: ["Picacg", "EHentai", "禁漫天堂".tl, "hitomi", "绅士漫画".tl, "nhentai"],
          inPopUpWidget: popUp,
        ),
      ),
      StatefulBuilder(builder: (context, setState){
        return ListTile(
          leading:
          const Icon(Icons.border_right),
          title: Text("启用侧边翻页栏".tl),
          trailing: Switch(
            value: appdata.settings[64] == "1",
            onChanged: (b){
              setState(() {
                appdata.settings[64] = b?"1":"0";
              });
              appdata.updateSettings();
            },
          ),
        );
      }),
      ListTile(
        leading: const Icon(Icons.image),
        title: Text("漫画块缩略图布局".tl),
        trailing: Select(
          initialValue: int.parse(appdata.settings[66]),
          whenChange: (i) {
            appdata.settings[66] = i.toString();
            appdata.updateSettings();
          },
          values: ["覆盖".tl, "容纳".tl],
        ),
      ),
      Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
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