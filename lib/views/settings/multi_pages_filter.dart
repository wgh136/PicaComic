import 'package:flutter/material.dart';

import '../../base.dart';
import '../../foundation/app.dart';

class MultiPagesFilter extends StatefulWidget {
  const MultiPagesFilter(this.title, this.settingsIndex, this.pages, {super.key});

  final String title;

  final int settingsIndex;

  // key - showName
  final Map<String, String> pages;

  @override
  State<MultiPagesFilter> createState() => _MultiPagesFilterState();
}

class _MultiPagesFilterState extends State<MultiPagesFilter> {
  late List<String> keys;

  @override
  void initState() {
    keys = appdata.settings[widget.settingsIndex].split(",");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if(keys.length < widget.pages.length)
            IconButton(onPressed: showAddDialog, icon: const Icon(Icons.add))
        ],
      ),
      body: ReorderableListView(
        children: keys.map((e) => buildItem(e)).toList(),
        onReorder: (oldIndex, newIndex){
          setState(() {
            var element = keys.removeAt(oldIndex);
            keys.insert(newIndex, element);
          });
          updateSetting();
        },
      ),
    );
  }

  Widget buildItem(String key){
    Widget removeButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
          onPressed: (){
            setState((){
              keys.remove(key);
            });
            updateSetting();
          },
          icon: const Icon(Icons.delete)
      ),
    );

    return ListTile(title: Text(widget.pages[key]!), key: Key(key), trailing: removeButton,);
  }

  void showAddDialog(){
    var canAdd = <String, String>{};
    widget.pages.forEach((key, value) {
      if(!keys.contains(key)){
        canAdd[key] = value;
      }
    });
    showDialog(context: context, builder: (context){
      return SimpleDialog(
        title: const Text("Add"),
        children: canAdd.entries.map((e) => InkWell(
          child: ListTile(title: Text(e.value), key: Key(e.key)),
          onTap: (){
            App.back(context);
            setState(() {
              keys.add(e.key);
            });
            updateSetting();
          },
        )).toList(),
      );
    });
  }

  void updateSetting(){
    appdata.settings[widget.settingsIndex] = keys.join(",");
    appdata.updateSettings();
  }
}
