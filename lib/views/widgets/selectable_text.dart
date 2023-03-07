import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SelectableTextCN extends StatelessWidget{
  //Flutter内置的SelectableText弹出菜单为英文, 这个对其作出修改
  const SelectableTextCN({required this.text,this.style,super.key});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      contextMenuBuilder: (context,state){
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: state.contextMenuAnchors,
          buttonItems: [
            ContextMenuButtonItem(
                onPressed: (){
                  Clipboard.setData(ClipboardData(text: state.currentTextEditingValue.text));
                  state.hideToolbar();
                },
                label: "复制"
            ),
            ContextMenuButtonItem(
                onPressed: (){
                  state.selectAll(SelectionChangedCause.toolbar);
                },
                label: "全选"
            ),
          ],
        );
      },
    );
  }
}