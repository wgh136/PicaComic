import 'package:flutter/material.dart';

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
                children: const [
                  ListTile(
                    title: Text("PicaComic"),
                    subtitle: SelectableText("本软件仅用于学习交流"),
                  ),
                  ListTile(
                    title: Text("版本"),
                    subtitle: SelectableText("v0.1"),
                  ),
                  ListTile(
                    title: Text("项目地址"),
                    subtitle: SelectableText(""),
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
