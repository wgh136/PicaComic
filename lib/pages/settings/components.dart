part of pica_settings;

class SwitchSetting extends StatefulWidget {
  const SwitchSetting(
      {required this.title,
      this.subTitle,
      required this.icon,
      required this.settingsIndex,
      super.key});

  final String title;

  final String? subTitle;

  final Widget icon;

  final int settingsIndex;

  @override
  State<SwitchSetting> createState() => _SwitchSettingState();
}

class _SwitchSettingState extends State<SwitchSetting> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      subtitle: widget.subTitle == null ? null : Text(widget.subTitle!),
      leading: widget.icon,
      trailing: Switch(
        value: appdata.settings[widget.settingsIndex] == '1',
        onChanged: (value) {
          setState(() {
            appdata.settings[widget.settingsIndex] = value ? '1' : '0';
            appdata.updateSettings();
          });
        },
      ),
    );
  }
}

class SettingsTitle extends StatelessWidget {
  const SettingsTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text),
    );
  }
}

class NewPageSetting extends StatelessWidget {
  const NewPageSetting(
      {required this.title,
      required this.onTap,
      required this.icon,
      super.key});

  final String title;

  final VoidCallback onTap;

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_right),
    );
  }
}

class SelectSettingWithAppdata extends StatelessWidget {
  const SelectSettingWithAppdata({
    super.key,
    required this.icon,
    required this.title,
    required this.settingsIndex,
    required this.options,
    this.onChanged,
  });

  final Widget icon;

  final String title;

  final int settingsIndex;

  final List<String> options;

  final void Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    return SelectSetting(
      leading: icon,
      title: title,
      values: options,
      onChanged: (i) {
        appdata.settings[settingsIndex] = i.toString();
        appdata.updateSettings();
        onChanged?.call();
      },
      initialValue: int.parse(appdata.settings[settingsIndex]),
    );
  }
}

class SelectSetting extends StatelessWidget {
  const SelectSetting({
    super.key,
    required this.leading,
    required this.title,
    required this.values,
    required this.onChanged,
    required this.initialValue,
  });

  final Widget leading;

  final String title;

  final List<String> values;

  final void Function(int i) onChanged;

  final int initialValue;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        bool small = constrains.maxWidth < 400;
        if (small) {
          return _SelectTile(
            icon: leading,
            title: title,
            options: values,
            onChange: onChanged,
            initialValue: initialValue,
          );
        }
        return ListTile(
          leading: leading,
          title: Text(title),
          trailing: Select(
            width: 136,
            initialValue: initialValue,
            onChange: onChanged,
            values: values,
          ),
        );
      },
    );
  }
}

class _SelectTile extends StatefulWidget {
  const _SelectTile({
    required this.icon,
    required this.title,
    required this.initialValue,
    required this.options,
    this.onChange,
  });

  final Widget icon;

  final String title;

  final int initialValue;

  final List<String> options;

  final void Function(int i)? onChange;

  @override
  State<_SelectTile> createState() => _SelectTileState();
}

class _SelectTileState extends State<_SelectTile> {
  var value = -1;

  @override
  void initState() {
    value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: widget.icon,
      title: Text(widget.title),
      subtitle: Text(value == -1 ? "无".tl : widget.options[value]),
      onTap: showOptions,
      trailing: const Icon(Icons.arrow_drop_down),
    );
  }

  void showOptions() {
    final renderBox = context.findRenderObject() as RenderBox;
    var offset = renderBox.localToGlobal(Offset.zero);
    showMenu<int>(
      context: App.globalContext!,
      initialValue: value == -1 ? null : value,
      position: RelativeRect.fromLTRB(
        offset.dx + renderBox.size.width,
        offset.dy,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      color: context.colorScheme.surfaceContainerLowest,
      items: [
        for (int i = 0; i < widget.options.length; i++)
          PopupMenuItem(
            value: i,
            height: 42,
            onTap: () {
              setState(() {
                value = i;
              });
              widget.onChange?.call(i);
            },
            child: Text(widget.options[i]),
          )
      ],
    );
  }
}
