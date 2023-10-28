import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';

class PopUpWidgetScaffold extends StatefulWidget {
  //为弹出的窗口提供的一个骨架
  const PopUpWidgetScaffold({required this.title,required this.body,this.tailing,Key? key}) : super(key: key);
  final Widget body;
  final List<Widget>? tailing;
  final String title;

  @override
  State<PopUpWidgetScaffold> createState() => _PopUpWidgetScaffoldState();
}

class _PopUpWidgetScaffoldState extends State<PopUpWidgetScaffold> {
  bool top = true;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(color: top?null:Theme.of(context).colorScheme.surfaceTint.withAlpha(20)),
            child: Row(
              children: [
                const SizedBox(width: 8,),
                Tooltip(
                  message: "返回",
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_sharp),
                    onPressed:()=>Navigator.of(context).canPop()?Navigator.of(context).pop():App.globalBack()
                  ),
                ),
                const SizedBox(width: 16,),
                Text(widget.title,style: const TextStyle(fontSize: 22,fontWeight: FontWeight.w500),),
                const Spacer(),
                if(widget.tailing!=null)
                  ...widget.tailing!
              ],
            ),
          ),
          NotificationListener<ScrollNotification>(
            onNotification: (notifications) {
              if(notifications.metrics.pixels == notifications.metrics.minScrollExtent && !top){
                setState(() {
                  top = true;
                });
              } else if(notifications.metrics.pixels != notifications.metrics.minScrollExtent && top){
                setState(() {
                  top = false;
                });
              }
              return false;
            },
            child: Expanded(child: widget.body),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom-0.05*MediaQuery.of(context).size.height>0?
          MediaQuery.of(context).viewInsets.bottom-0.05*MediaQuery.of(context).size.height:0
            ,)
        ],
      ),
    );
  }
}
