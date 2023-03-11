import 'package:flutter/material.dart';

class PopUpWidgetScaffold extends StatelessWidget {
  //为弹出的窗口提供的一个骨架
  const PopUpWidgetScaffold({required this.title,required this.body,this.tailing,Key? key}) : super(key: key);
  final Widget body;
  final Widget? tailing;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant),
            child: Row(
              children: [
                if(Navigator.of(context).canPop())
                Tooltip(
                  message: "返回",
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_sharp),
                    onPressed:()=>Navigator.of(context).pop()
                  ),
                ),
                const SizedBox(width: 16,),
                Text(title,style: const TextStyle(fontSize: 24),),
                const Spacer(),
                if(tailing!=null)
                  tailing!
              ],
            ),
          ),
          Expanded(child: body)
        ],
      ),
    );
  }
}
