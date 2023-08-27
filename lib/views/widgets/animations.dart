import 'package:flutter/material.dart';

class AnimatedCheckWidget extends AnimatedWidget{
  const AnimatedCheckWidget({super.key, required Animation<double> animation, this.size})
      : super(listenable: animation);

  final double? size;

  @override
  Widget build(BuildContext context) {
    var iconSize = size ?? IconTheme.of(context).size ?? 25;
    final animation = listenable as Animation<double>;
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: animation.value,
          child: ClipRRect(
            child: Icon(Icons.check, size: iconSize, color:Theme.of(context).colorScheme.primary,),
          ),
        ),
      ),
    );
  }
}

class AnimatedCheckIcon extends StatefulWidget {
  const AnimatedCheckIcon({this.size, super.key});

  final double? size;

  @override
  State<AnimatedCheckIcon> createState() => _AnimatedCheckIconState();
}

class _AnimatedCheckIconState extends State<AnimatedCheckIcon> with SingleTickerProviderStateMixin{
  late Animation<double> animation;
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    animation = Tween<double>(begin: 0, end: 1).animate(controller)
      ..addListener(() {
        setState(() {});
      });
    controller.forward();
    super.initState();
  }


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCheckWidget(animation: animation, size: widget.size,);
  }
}