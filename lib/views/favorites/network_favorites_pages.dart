import 'package:pica_comic/comic_source/favorites.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/favorites/network_favorite_page.dart';

import '../../base.dart';

class NetworkFavoritesPages extends StatefulWidget {
  const NetworkFavoritesPages({Key? key}) : super(key: key);

  @override
  State<NetworkFavoritesPages> createState() => _NetworkFavoritesPagesState();
}

class _NetworkFavoritesPagesState extends State<NetworkFavoritesPages>
    with SingleTickerProviderStateMixin {
  late TabController controller;

  late final List<FavoriteData> _folders;

  @override
  void initState() {
    var folders = <FavoriteData>[];
    for(var key in appdata.settings[68].split(',')){
      folders.add(getFavoriteData(key));
    }
    _folders = folders;
    controller = TabController(length: _folders.length, vsync: this);
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTabBar(),
        const Divider(height: 1,),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: _folders.map((e) => NetworkFavoritePage(e)).toList(),
          ),
        )
      ],
    );
  }

  Widget buildTabBar() {
    final folders = _folders.map((e) => e.title).toList();

    Widget buildTab(int index, [bool all=false]){
      var showName = folders[index];
      bool selected = index == controller.index;
      return InkWell(
        key: Key(showName),
        borderRadius: BorderRadius.circular(8),
        splashColor: App.colors(context).primary.withOpacity(0.2),
        onTap: (){
          setState(() {});
          controller.animateTo(index);
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                border: selected ? Border(bottom: BorderSide(color: App.colors(context).primary, width: 2)) : null
            ),
            child: Center(
              child: Text(showName, style: TextStyle(
                color: selected ? App.colors(context).primary : null,
                fontWeight: FontWeight.w600,
              ),),
            ),
          ),
        ),
      );
    }

    return Material(
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8,),
              for(int i=0; i<folders.length; i++)
                buildTab(i),
              const SizedBox(width: 8,),
            ],
          ),
        ),
      ),
    );
  }
}
