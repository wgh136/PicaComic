import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/animations.dart';

class CustomFilterChip extends StatefulWidget {
  /// FilterChip in material library will change width when it's status changed.
  ///
  /// This widget has fixed width.
  const CustomFilterChip({required this.label, required this.selected, required this.onSelected, super.key});

  final Widget label;

  final bool selected;

  final void Function(bool) onSelected;

  @override
  State<CustomFilterChip> createState() => _CustomFilterChipState();
}

class _CustomFilterChipState extends State<CustomFilterChip> {
  get selected => widget.selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      textStyle: Theme.of(context).textTheme.labelLarge,
      child: InkWell(
        onTap: () => widget.onSelected(true),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              color: selected ? Theme.of(context).colorScheme.primaryContainer : null
          ),
          padding: const EdgeInsets.fromLTRB(4, 7, 4, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(!selected)
                const SizedBox(width: 20,)
              else
                const SizedBox(width: 7,),
              if(selected)
                const AnimatedCheckIcon(size: 16),
              if(selected)
                const SizedBox(width: 5,),
              widget.label,
              if(!selected)
                const SizedBox(width: 20,)
              else
                const SizedBox(width: 12,),
            ],
          ),
        ),
      ),
    );
  }
}
