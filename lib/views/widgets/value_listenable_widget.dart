import 'package:flutter/material.dart';

class ValueListenableWidget<T> extends StatefulWidget {
  /// A simple StatefulWidget
  const ValueListenableWidget({required this.initialValue, required this.builder, super.key});

  final T initialValue;

  final Widget Function(T value, void Function(T) update) builder;

  @override
  State<ValueListenableWidget<T>> createState() => _ValueListenableWidgetState<T>();
}

class _ValueListenableWidgetState<T> extends State<ValueListenableWidget<T>> {
  late T value = widget.initialValue;

  @override
  Widget build(BuildContext context) =>
      widget.builder(value, (newValue)=>setState(() => value = newValue));
}
