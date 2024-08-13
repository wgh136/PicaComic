part of "components.dart";

class StatefulValueBuilder<T> extends StatefulWidget {
  /// A simple StatefulWidget
  const StatefulValueBuilder(
      {required this.initialValue, required this.builder, super.key});

  final T initialValue;

  final Widget Function(T value, void Function(T) update) builder;

  @override
  State<StatefulValueBuilder<T>> createState() =>
      _StatefulValueBuilderState<T>();
}

class _StatefulValueBuilderState<T> extends State<StatefulValueBuilder<T>> {
  late T value = widget.initialValue;

  @override
  Widget build(BuildContext context) =>
      widget.builder(value, (newValue) => setState(() => value = newValue));
}
