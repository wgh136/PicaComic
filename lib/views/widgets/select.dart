import 'package:flutter/material.dart';

class Select extends StatefulWidget {
  const Select({
    required this.initialValue,
    this.width=120,
    required this.whenChange,
    Key? key,
    required this.values,
    this.inPopUpWidget=false,
    this.disabledValues=const []
  }) : super(key: key);
  ///初始值, 提供values的下标
  final int initialValue;
  ///可供选取的值
  final List<String> values;
  ///宽度
  final double width;
  ///发生改变时的回调
  final void Function(int) whenChange;
  final bool inPopUpWidget;
  final List<int> disabledValues;

  @override
  State<Select> createState() => _SelectState();
}

class _SelectState extends State<Select> {
  late int value = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: (){
        final renderBox = context.findRenderObject() as RenderBox;
        var offset = renderBox.localToGlobal(Offset.zero);
        var size = widget.inPopUpWidget?Size(550, MediaQuery.of(context).size.height*0.9):MediaQuery.of(context).size;
        if(widget.inPopUpWidget){
          offset = Offset(
            offset.dx - (MediaQuery.of(context).size.width-size.width)/2,
            offset.dy - MediaQuery.of(context).size.height*0.05
          );
        }
        showMenu<int>(
            context: context,
            initialValue: value,
            position: RelativeRect.fromLTRB(offset.dx+widget.width, offset.dy+20, size.width-offset.dx-widget.width, size.height-offset.dy-20),
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
      child: SizedBox(
        width: widget.width,
        height: 38,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              const SizedBox(width: 16,),
              Expanded(child: Text(widget.values[value], overflow: TextOverflow.fade,),),
              const Icon(Icons.arrow_drop_down_sharp)
            ],
          ),
        ),
      ),
    );
  }
}
