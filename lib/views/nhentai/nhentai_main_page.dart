import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';

class NhentaiHomePage extends StatelessWidget {
  const NhentaiHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        child: const Text("Debug"),
        onPressed: (){
          NhentaiNetwork().get();
        },
      ),
    );
  }
}
