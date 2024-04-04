import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/select.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import '../main.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool agree = false;

  @override
  Widget build(BuildContext context){
    final width = MediaQuery.of(context).size.width;

    var padding = 16.0;

    if(width > 900){
      padding += (width - 900) / 2;
    }

    final bool showTwoPanel = width > 680;


    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, 0, padding, 0),
        child: Column(
          children: [
            SizedBox(height: 16 + MediaQuery.of(context).padding.top,),
            const SizedBox(
              height: 100,
              width: double.infinity,
              child: Center(
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircleAvatar(
                    backgroundImage: AssetImage("images/app_icon.png"),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                "欢迎".tl,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(height: 16,),
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("使用须知".tl, style: const TextStyle(fontSize: 22),),
                    const SizedBox(height: 8,),
                    Text(
                      "感谢使用本软件, 请注意:".tl,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text("本App的开发目的仅为学习交流与个人兴趣, 显示的任何内容均来自网络, ".tl+
                        "与开发者无关.此项目与Picacg, e-hentai.org, JmComic, ".tl+
                        "hitomi.la, 紳士漫畫, nhentai无任何关系.如果在使用中发现问题, ".tl+
                        "请先确认是否为自己的设备问题, 然后再进行反馈.".tl,
                    ),
                    const SizedBox(height: 4,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("我已阅读并知晓".tl, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),),
                        Checkbox(value: agree, onChanged: (b){
                          setState(() {
                            agree = b ?? false;
                          });
                        })
                      ],
                    )
                  ],
                ),
              ),
            ),
            if(showTwoPanel)
              SizedBox(
                height: 258,
                child: Row(
                  children: [
                    Expanded(
                      child: buildShowModeSetting(),
                    ),
                    Expanded(
                      child: buildAppearanceSettings(258),
                    )
                  ],
                ),
              ),
            if(!showTwoPanel)
              SizedBox(
                height: 196,
                child: buildShowModeSetting(),
              ),
            if(!showTwoPanel)
              SizedBox(
                child: buildAppearanceSettings(),
              ),
            SizedBox(
              child: buildReadingSettings(),
            ),
            if(showTwoPanel)
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    Expanded(
                      child: showMoreSetting(),
                    ),
                    Expanded(
                      child: loginAccount(),
                    )
                  ],
                ),
              ),
            if(!showTwoPanel)
              SizedBox(
                height: 56,
                child: showMoreSetting(),
              ),
            if(!showTwoPanel)
              SizedBox(
                height: 56,
                child: loginAccount(),
              ),
            const SizedBox(height: 16,),
            Center(
              child: FilledButton(
                onPressed: () {
                  if(agree){
                    App.globalOff(() => const MainPage());
                  } else {
                    showMessage(context, "请先阅读使用须知".tl);
                  }
                },
                child: Text("进入APP".tl),
              ),
            ),
            const SizedBox(height: 16,),
          ],
        ),
      ),
    );
  }

  Widget buildShowModeSetting(){
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "漫画列表显示方式".tl,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 8,
            ),
            RadioListTile<String>(
                title: Text("顺序显示".tl),
                value: "0",
                groupValue: appdata.settings[25],
                onChanged: (s) {
                  setState(() {
                    appdata.settings[25] = s!;
                  });
                  appdata.updateSettings();
                }),
            RadioListTile<String>(
                title: Text("分页显示".tl),
                value: "1",
                groupValue: appdata.settings[25],
                onChanged: (s) {
                  setState(() {
                    appdata.settings[25] = s!;
                  });
                  appdata.updateSettings();
                }),
          ],
        ),
      ),
    );
  }

  Widget buildAppearanceSettings([double? height]){
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "设置App外观".tl,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 8,
            ),
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: Text("主题选择".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[27]),
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
                whenChange: (i) {
                  appdata.settings[27] = i.toString();
                  appdata.updateSettings();
                  MyApp.updater?.call();
                },
                inPopUpWidget: false,
                width: 140,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: Text("深色模式".tl),
              trailing: Select(
                initialValue: int.parse(appdata.settings[32]),
                values: ["跟随系统".tl, "禁用".tl, "启用".tl],
                whenChange: (i) {
                  appdata.settings[32] = i.toString();
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
              ),
            ),
            const SizedBox(
              height: 8,
            )
          ],
        ),
      ),
    );
  }

  Widget showMoreSetting(){
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: NewSettingsPage.open,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
            child: Row(
              children: [
                const SizedBox(width: 12,),
                const Icon(Icons.settings,),
                const SizedBox(width: 8,),
                Text(
                  "更多设置".tl,
                  style: const TextStyle(fontSize: 18),
                ),
                const Spacer(),
                const Icon(Icons.arrow_right),
                const SizedBox(width: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget loginAccount(){
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showAdaptiveWidget(
              context,
              AccountsPage()),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
            child: Row(
              children: [
                const SizedBox(width: 12,),
                const Icon(Icons.account_circle,),
                const SizedBox(width: 8,),
                Text(
                  "登录账号".tl,
                  style: const TextStyle(fontSize: 18),
                ),
                const Spacer(),
                const Icon(Icons.arrow_right),
                const SizedBox(width: 12,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildReadingSettings(){
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "阅读设置".tl,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(
              height: 8,
            ),
            const ReadingSettings(false)
          ],
        ),
      ),
    );
  }
}