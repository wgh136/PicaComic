part of pica_settings;

class MultiPagesFilter extends StatefulWidget {
  const MultiPagesFilter(this.title, this.settingsIndex, this.pages,
      {super.key});

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
    keys.remove("");
    super.initState();
  }

  var reorderWidgetKey = UniqueKey();
  var scrollController = ScrollController();
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    var tiles = keys.map((e) => buildItem(e)).toList();

    var view = ReorderableBuilder(
      key: reorderWidgetKey,
      scrollController: scrollController,
      longPressDelay: App.isDesktop
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 500),
      dragChildBoxDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        boxShadow: const [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
              spreadRadius: 2)
        ],
      ),
      onReorder: (reorderFunc) {
        setState(() {
          keys = List.from(reorderFunc(keys));
        });
        updateSetting();
      },
      children: tiles,
      builder: (children) {
        return GridView(
          key: _key,
          controller: scrollController,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            mainAxisExtent: 48,
          ),
          children: children,
        );
      },
    );

    return PopUpWidgetScaffold(
      title: widget.title,
      tailing: [
        if (keys.length < widget.pages.length)
          IconButton(onPressed: showAddDialog, icon: const Icon(Icons.add))
      ],
      body: view,
    );
  }

  Widget buildItem(String key) {
    Widget removeButton = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
          onPressed: () {
            setState(() {
              keys.remove(key);
            });
            updateSetting();
          },
          icon: const Icon(Icons.delete)),
    );

    return ListTile(
      title: Text(widget.pages[key] ?? "(Invalid) $key"),
      key: Key(key),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          removeButton,
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }

  void showAddDialog() {
    var canAdd = <String, String>{};
    widget.pages.forEach((key, value) {
      if (!keys.contains(key)) {
        canAdd[key] = value;
      }
    });
    showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Add"),
            children: canAdd.entries
                .map((e) => InkWell(
                      child: ListTile(title: Text(e.value), key: Key(e.key)),
                      onTap: () {
                        App.back(context);
                        setState(() {
                          keys.add(e.key);
                        });
                        updateSetting();
                      },
                    ))
                .toList(),
          );
        });
  }

  void updateSetting() {
    appdata.settings[widget.settingsIndex] = keys.join(",");
    appdata.updateSettings();
  }
}
