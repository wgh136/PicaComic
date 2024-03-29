part of pica_settings;

class SwitchSetting extends StatefulWidget {
  const SwitchSetting({required this.title, this.subTitle, required this.icon,
    required this.settingsIndex, super.key});

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
        onChanged: (value){
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
    return ListTile(title: Text(text),);
  }
}

class NewPageSetting extends StatelessWidget {
  const NewPageSetting({required this.title, required this.onTap,
    required this.icon, super.key});

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

class SelectSetting extends StatelessWidget {
  const SelectSetting({super.key, required this.icon, required this.title,
    this.subTitle, required this.settingsIndex, required this.options,
    this.onChange});

  final Widget icon;

  final String title;

  final String? subTitle;

  final int settingsIndex;

  final List<String> options;

  final void Function()? onChange;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(title),
      trailing: Select(
        initialValue: int.parse(appdata.settings[settingsIndex]),
        whenChange: (i) {
          appdata.settings[settingsIndex] = i.toString();
          appdata.updateSettings();
          onChange?.call();
        },
        values: options,
      ),
    );
  }
}

