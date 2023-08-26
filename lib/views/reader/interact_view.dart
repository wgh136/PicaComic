import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

extension InteractViewExtention on TransformationController{
  Matrix4 _composeMatrix({
    double scale = 1,
    double rotation = 0,
    double translateX = 0,
    double translateY = 0,
    double anchorX = 0,
    double anchorY = 0,
  }) {
    final double c = cos(rotation) * scale;
    final double s = sin(rotation) * scale;
    final double dx = translateX - c * anchorX + s * anchorY;
    final double dy = translateY - s * anchorX - c * anchorY;
    return Matrix4(c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1);
  }

  Matrix4 _composeMatrixFromOffsets({
    double scale = 1,
    double rotation = 0,
    Offset translate = Offset.zero,
    Offset anchor = Offset.zero,
  }) =>
      _composeMatrix(
        scale: scale,
        rotation: rotation,
        translateX: translate.dx,
        translateY: translate.dy,
        anchorX: anchor.dx,
        anchorY: anchor.dy,
      );

  void zoom(double value) => scale = scale + value;

  set scale(double scale){
    if(scale < 1) return;
    final center = MediaQuery.of(Get.context!).size.center(Offset.zero);
    final anchor = toScene(center);
    value = _composeMatrixFromOffsets(scale: scale, anchor: anchor, translate: center);
    updateLocation(Offset.zero);
  }

  void updateLocation(Offset offset){
    final center = MediaQuery.of(Get.context!).size.center(Offset.zero);
    final newAnchor = toScene(center) + offset;

    final limit = center.dy / scale;

    // Clamp the newAnchor Y-coordinate to prevent exceeding minY
    final clampedY = newAnchor.dy.clamp(limit, center.dy*2 - limit);

    final clampedAnchor = Offset(newAnchor.dx, clampedY);

    // Update the transformation matrix with the clamped anchor
    value = _composeMatrixFromOffsets(
      scale: scale,
      translate: center,
      anchor: clampedAnchor,
    );
  }

  double get scale => value.getMaxScaleOnAxis();
}