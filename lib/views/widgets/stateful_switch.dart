import 'package:flutter/material.dart';

class StatefulSwitch extends StatefulWidget {
  const StatefulSwitch({required this.initialValue, required this.onChanged, super.key});

  final bool initialValue;

  final void Function(bool) onChanged;

  @override
  State<StatefulSwitch> createState() => _StatefulSwitchState();
}

class _StatefulSwitchState extends State<StatefulSwitch> {
  late bool value;

  @override
  void initState() {
    value = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(value: value, onChanged: (b){
      setState(() {
        value = b;
        widget.onChanged(b);
      });
    });
  }
}
