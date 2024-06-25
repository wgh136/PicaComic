import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs"),
        actions: [
          IconButton(onPressed: ()=>setState(() {
            final RelativeRect position = RelativeRect.fromLTRB(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).padding.top + kToolbarHeight,
              0.0,
              0.0,
            );
            showMenu(context: context, position: position, items: [
              PopupMenuItem(
                child: const Text("清空"),
                onTap: () => setState(()=>LogManager.clear()),
              ),
              PopupMenuItem(
                child: const Text("禁用长度限制"),
                onTap: (){
                  LogManager.ignoreLimitation = true;
                  showMessage(context, "仅在本次运行时有效");
                },
              ),
              PopupMenuItem(
                child: const Text("导出"),
                onTap: () => saveLog(LogManager().toString()),
              ),
            ]);
          }), icon: const Icon(Icons.more_horiz))
        ],
      ),
      body: ListView.builder(
        reverse: true,
        controller: ScrollController(),
        itemCount: LogManager.logs.length,
        itemBuilder: (context, index){
          index =  LogManager.logs.length - index - 1;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 1),
                          child: Text(LogManager.logs[index].title),
                        ),
                      ),
                      const SizedBox(width: 3,),
                      Container(
                        decoration: BoxDecoration(
                          color: [
                            Theme.of(context).colorScheme.error,
                            Theme.of(context).colorScheme.errorContainer,
                            Theme.of(context).colorScheme.primaryContainer
                          ][LogManager.logs[index].level.index],
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 1),
                          child: Text(
                            LogManager.logs[index].level.name,
                            style: TextStyle(color: LogManager.logs[index].level.index==0?Colors.white:Colors.black),),
                        ),
                      ),
                    ],
                  ),
                  Text(LogManager.logs[index].content),
                  Text(LogManager.logs[index].time.toString().replaceAll(RegExp(r"\.\w+"), "")),
                  TextButton(onPressed: (){
                    Clipboard.setData(ClipboardData(text: LogManager.logs[index].content));
                  }, child: const Text("复制")),
                  const Divider(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
