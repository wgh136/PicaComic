import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';

class ListLoadingIndicator extends StatelessWidget {
  const ListLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: SizedBox(
          width: 100,
          height: 60,
          child: Row(
            children: [
              const SizedBox(
                width: 25,
                height: 25,
                child: CircularProgressIndicator(strokeWidth: 3,),
              ),
              Text("  ${"加载中".tl}...")
            ],
          ),
        ),
      ),
    );
  }
}
