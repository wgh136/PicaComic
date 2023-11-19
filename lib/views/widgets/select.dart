import 'package:flutter/material.dart';

import '../../foundation/app.dart';

class Select extends StatefulWidget {
  const Select({
    required this.initialValue,
    this.width=120,
    required this.whenChange,
    Key? key,
    required this.values,
    bool? inPopUpWidget,
    this.disabledValues=const [],
    this.outline = false,
  }) : super(key: key);
  ///初始值, 提供values的下标
  final int? initialValue;
  ///可供选取的值
  final List<String> values;
  ///宽度
  final double width;
  ///发生改变时的回调
  final void Function(int) whenChange;
  final List<int> disabledValues;
  final bool outline;

  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  late int? value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    if(value != null && value! < 0) value = null;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: (){
        if(widget.values.isEmpty){
          return;
        }
        final renderBox = context.findRenderObject() as RenderBox;
        var offset = renderBox.localToGlobal(Offset.zero);
        var size = MediaQuery.of(context).size;
        showMenu<int>(
            context: App.globalContext!,
            initialValue: value,
            position: RelativeRect.fromLTRB(offset.dx, offset.dy+20, offset.dx+widget.width, size.height-offset.dy-20),
            constraints: BoxConstraints(
              maxWidth: widget.width,
              minWidth: widget.width,
            ),
            items: [
              for(int i = 0; i < widget.values.length; i++)
                if(! widget.disabledValues.contains(i))
                  PopupMenuItem(
                    value: i,
                    onTap: (){
                      setState(() {
                        value = i;
                        widget.whenChange(i);
                      });
                    },
                    child: Text(widget.values[i]),
                  )
            ]
        );
      },
      child: Container(
        margin: EdgeInsets.zero,
        width: widget.width,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.outline ? 4 : 8),
          color: widget.outline ? null : Theme.of(context).colorScheme.secondaryContainer,
          border: widget.outline ? Border.all(color: Theme.of(context).colorScheme.outline) : null
        ),
        child: Row(
          children: [
            const SizedBox(width: 16,),
            Expanded(
              child: Text(value == null ? "" : widget.values[value!],
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down_sharp)
          ],
        ),
      ),
    );
  }
}
