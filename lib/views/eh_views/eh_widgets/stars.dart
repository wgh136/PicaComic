import 'package:flutter/material.dart';

class RatingWidget extends StatefulWidget {
  /// star number
  final int count;

  /// Max score
  final double maxRating;

  /// Current score value
  final double value;

  /// Star size
  final double size;

  /// Space between the stars
  final double padding;

  /// Whether the score can be modified by sliding
  final bool selectAble;

  /// Callbacks when ratings change
  final ValueChanged<double> onRatingUpdate;

  const RatingWidget({
    super.key,
    this.maxRating = 10.0,
    this.count = 5,
    this.value = 10.0,
    this.size = 20,
    required this.padding,
    this.selectAble = false,
    required this.onRatingUpdate
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  double value = 10;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        double x = event.localPosition.dx;
        if (x < 0) x = 0;
        pointValue(x);
      },
      onPointerMove: (PointerMoveEvent event) {
        double x = event.localPosition.dx;
        if (x < 0) x = 0;
        pointValue(x);
      },
      onPointerUp: (_) {},
      behavior: HitTestBehavior.deferToChild,
      child: buildRowRating(),
    );
  }

  pointValue(double dx) {
    if (!widget.selectAble) {
      return;
    }
    if (dx >= widget.size * widget.count + widget.padding * (widget.count - 1)) {
      value = widget.maxRating;
    } else {
      for (double i = 1; i < widget.count + 1; i++) {
        if (dx > widget.size * i + widget.padding * (i - 1) &&
            dx < widget.size * i + widget.padding * i) {
          value = i * (widget.maxRating / widget.count);
          break;
        } else if (dx > widget.size * (i - 1) + widget.padding * (i - 1) &&
            dx < widget.size * i + widget.padding * i) {
          value = (dx - widget.padding * (i - 1)) /
              (widget.size * widget.count) *
              widget.maxRating;
          break;
        }
      }
    }
    if(value % 1 >=0.5){
      value = value ~/ 1 + 1;
    }else{
      value = (value ~/ 1).toDouble();
    }
    if(value < 0){
      value = 0;
    }else if(value > 10){
      value = 10;
    }
    setState(() {
      widget.onRatingUpdate(value);
    });
  }

  int fullStars() {
    return (value / (widget.maxRating / widget.count)).floor();
  }

  double star() {
    if (widget.count / fullStars() == widget.maxRating / value) {
      return 0;
    }
    return (value % (widget.maxRating / widget.count)) /
        (widget.maxRating / widget.count);
  }

  List<Widget> buildRow() {
    int full = fullStars();
    List<Widget> children = [];
    for (int i = 0; i < full; i++) {
      children.add(Icon(Icons.star,size: widget.size,color: Theme.of(context).colorScheme.secondary));
      if (i < widget.count - 1) {
        children.add(
          SizedBox(
            width: widget.padding,
          ),
        );
      }
    }
    if (full < widget.count) {
      children.add(ClipRect(
        clipper: SMClipper(rating: star() * widget.size),
        child: Icon(Icons.star,size: widget.size,color: Theme.of(context).colorScheme.secondary),
      ));
    }

    return children;
  }

  List<Widget> buildNormalRow() {
    List<Widget> children = [];
    for (int i = 0; i < widget.count; i++) {
      children.add(Icon(Icons.star_border,size: widget.size,color: Theme.of(context).colorScheme.secondary,));
      if (i < widget.count - 1) {
        children.add(SizedBox(
          width: widget.padding,
        ));
      }
    }
    return children;
  }

  Widget buildRowRating() {
    return Stack(
      children: <Widget>[
        Row(
          children: buildNormalRow(),
        ),
        Row(
          children: buildRow(),
        )
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    value = widget.value;
  }
}

class SMClipper extends CustomClipper<Rect> {
  final double rating;
  SMClipper({required this.rating});
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0.0, 0.0, rating, size.height);
  }

  @override
  bool shouldReclip(SMClipper oldClipper) {
    return rating != oldClipper.rating;
  }
}