import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            centerTitle: true,
            title: const Text("关于"),
          ),
          SliverToBoxAdapter(
            child: Card(
              elevation: 0,
              child: Column(
                children: [
                  const ListTile(
                    title: Text("PicaComic"),
                    subtitle: SelectableText("本软件仅用于学习交流"),
                  ),
                  const ListTile(
                    title: Text("版本"),
                    subtitle: SelectableText("v0.1"),
                  ),
                  ListTile(
                    title: const Text("项目地址"),
                    subtitle: const SelectableText("https://github.com/wgh136/PicaComic"),
                    onTap: (){
                      launchUrlString("https://github.com/wgh136/PicaComic",mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),
            )
          )
        ],
      ),
    );
  }
}
