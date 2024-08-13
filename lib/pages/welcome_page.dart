import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/pages/main_page.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'settings/settings_page.dart';

import '../main.dart';
import 'accounts_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  var controller = PageController();

  int page = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colorScheme.surfaceContainerLow,
      child: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 500),
          child: Material(
            color: context.brightness == Brightness.light
                ? Colors.white
                : Colors.black,
            elevation: 1,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox.expand(
              child: PageView(
                controller: controller,
                onPageChanged: (i) {
                  page = i;
                },
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _AppIcon(),
                  _AppInfo(),
                  _AppAppearance(),
                  _ComicsDisplaySettings(),
                  _ReadingSettings(),
                  _ComicSource(),
                  _More(),
                ],
              ),
            ),
          ),
        ).toCenter(),
      )),
    );
  }

  void next() {
    controller.animateToPage((controller.page! + 1).round(),
        duration: const Duration(milliseconds: 200), curve: Curves.ease);
  }

  void back() {
    controller.animateToPage((controller.page! - 1).round(),
        duration: const Duration(milliseconds: 200), curve: Curves.ease);
  }
}

mixin class _WelcomePageComponents {
  Widget buildTitle(String title) {
    return Text(title, style: ts.s28).paddingVertical(16);
  }

  Widget buildBottom(BuildContext context, int page, [bool canNext = true]) {
    var state = context.findAncestorStateOfType<_WelcomePageState>()!;
    return Row(
      children: [
        if (page != 0)
          Button.text(
              padding: const EdgeInsets.fromLTRB(12, 6, 24, 6),
              onPressed: state.back,
              child: Row(
                children: [
                  const Icon(Icons.arrow_left),
                  const SizedBox(
                    width: 4,
                  ),
                  Text("返回".tl)
                ],
              )),
        const Spacer(),
        if (page != 6)
          Button.filled(
              padding: const EdgeInsets.fromLTRB(24, 6, 12, 6),
              onPressed: state.next,
              disabled: !canNext,
              child: Row(
                children: [
                  Text("继续".tl),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(Icons.arrow_right),
                ],
              ))
        else
          Button.filled(
              padding: const EdgeInsets.fromLTRB(24, 6, 12, 6),
              onPressed: () async {
                await ComicSource.reload();
                if (context.mounted) {
                  context.to(() => const MainPage());
                }
              },
              disabled: !canNext,
              child: Row(
                children: [
                  Text("完成".tl),
                  const SizedBox(
                    width: 4,
                  ),
                  const Icon(Icons.check),
                ],
              ))
      ],
    ).paddingVertical(12);
  }

  Widget buildView({required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ).paddingHorizontal(24);
  }
}

class _AppIcon extends StatelessWidget with _WelcomePageComponents {
  const _AppIcon();

  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("欢迎".tl),
        Expanded(
          child: Center(
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  image: const DecorationImage(
                      image: AssetImage("images/app_icon_no_bg.png"),
                      filterQuality: FilterQuality.medium)),
            ),
          ),
        ),
        buildBottom(context, 0)
      ],
    );
  }
}

class _AppInfo extends StatefulWidget {
  const _AppInfo();

  @override
  State<_AppInfo> createState() => _AppInfoState();
}

class _AppInfoState extends State<_AppInfo> with _WelcomePageComponents {
  bool agree = false;

  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("使用须知".tl),
        Text(
          buildInfo(),
          style: ts.s16.withHeight(2),
        ),
        const SizedBox(
          height: 16,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "我已阅读并知晓".tl,
              style: ts.withColor(context.colorScheme.primary),
            ),
            Checkbox(
                value: agree,
                onChanged: (b) {
                  setState(() {
                    agree = b ?? false;
                  });
                })
          ],
        ),
        const Spacer(),
        buildBottom(context, 1, agree)
      ],
    );
  }

  String buildInfo() {
    var content = '';
    content += "感谢使用本软件, 请注意:".tl;
    content += '\n';
    content += "本App的开发目的仅为学习交流与个人兴趣, 显示的任何内容均来自网络, 与开发者无关".tl;
    content += '\n';
    content += "如果在使用中发现问题, 请先确认是否为自己的设备问题, 然后再进行反馈".tl;
    content += '\n';
    content += "开发者不对能否解决问题负责".tl;
    return content;
  }
}

class _AppAppearance extends StatefulWidget {
  const _AppAppearance();

  @override
  State<_AppAppearance> createState() => _AppAppearanceState();
}

class _AppAppearanceState extends State<_AppAppearance>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("设置App外观".tl),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text("主题选择".tl),
          trailing: Select(
            initialValue: appdata.appSettings.theme,
            values: const [
              "dynamic",
              "Blue",
              "Light Blue",
              "Indigo",
              "Purple",
              "Pink",
              "Cyan",
              "Teal",
              "Yellow",
              "Brown"
            ],
            onChange: (i) {
              appdata.appSettings.theme = i;
              appdata.updateSettings();
              MyApp.updater?.call();
            },
            width: 140,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: Text("深色模式".tl),
          trailing: Select(
            initialValue: appdata.appSettings.darkMode,
            values: ["跟随系统".tl, "禁用".tl, "启用".tl],
            onChange: (i) {
              appdata.appSettings.darkMode = i;
              appdata.updateSettings();
              MyApp.updater?.call();
            },
            width: 140,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.crop_square),
          title: Text("漫画块显示模式".tl),
          trailing: Select(
            initialValue: appdata.appSettings.comicTileDisplayType,
            onChange: (i) {
              appdata.appSettings.comicTileDisplayType = i;
              appdata.updateSettings();
              MyApp.updater?.call();
            },
            values: ["详细".tl, "简略".tl],
          ),
        ),
        const Spacer(),
        buildBottom(context, 2)
      ],
    );
  }
}

class _ComicsDisplaySettings extends StatefulWidget {
  const _ComicsDisplaySettings();

  @override
  State<_ComicsDisplaySettings> createState() => _ComicsDisplaySettingsState();
}

class _ComicsDisplaySettingsState extends State<_ComicsDisplaySettings>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("漫画列表显示方式".tl),
        RadioListTile<int>(
            title: Text("连续模式".tl),
            value: 0,
            groupValue: appdata.appSettings.comicsListDisplayType,
            onChanged: (s) {
              setState(() {
                appdata.appSettings.comicsListDisplayType = s!;
              });
              appdata.updateSettings();
            }),
        Text("滑动到底部时自动加载下一页并追加到页面末尾".tl).paddingHorizontal(16),
        const SizedBox(
          height: 16,
        ),
        RadioListTile<int>(
            title: Text("分页模式".tl),
            value: 1,
            groupValue: appdata.appSettings.comicsListDisplayType,
            onChanged: (s) {
              setState(() {
                appdata.appSettings.comicsListDisplayType = s!;
              });
              appdata.updateSettings();
            }),
        Text("需要手动切换页面".tl).paddingHorizontal(16),
        const Spacer(),
        buildBottom(context, 3)
      ],
    );
  }
}

class _ReadingSettings extends StatelessWidget with _WelcomePageComponents {
  const _ReadingSettings();

  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("阅读设置".tl),
        const Expanded(
          child: SingleChildScrollView(
            child: ReadingSettings(false),
          ),
        ),
        buildBottom(context, 4)
      ],
    );
  }
}

class _ComicSource extends StatefulWidget {
  const _ComicSource();

  @override
  State<_ComicSource> createState() => _ComicSourceState();
}

class _ComicSourceState extends State<_ComicSource>
    with _WelcomePageComponents {
  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("漫画源".tl),
        Expanded(
          child: ListView.builder(
            itemCount: builtInSources.length,
            itemBuilder: (context, index) {
              var key = builtInSources[index];
              return ListTile(
                title: Text(
                    ComicSource.builtIn.firstWhere((e) => e.key == key).name),
                trailing: Switch(
                  value: appdata.appSettings.isComicSourceEnabled(key),
                  onChanged: (v) {
                    appdata.appSettings.setComicSourceEnabled(key, v);
                    appdata.updateSettings();
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
        buildBottom(context, 5)
      ],
    );
  }
}

class _More extends StatelessWidget with _WelcomePageComponents {
  const _More();

  @override
  Widget build(BuildContext context) {
    return buildView(
      children: [
        buildTitle("更多".tl),
        ListTile(
          leading: const Icon(
            Icons.account_circle,
          ),
          title: Text("登录账户".tl),
          onTap: () => showPopUpWidget(context, AccountsPage()),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: const Icon(
            Icons.settings,
          ),
          title: Text("更多设置".tl),
          onTap: SettingsPage.open,
          trailing: const Icon(Icons.arrow_right),
        ),
        const Spacer(),
        buildBottom(context, 6)
      ],
    );
  }
}
