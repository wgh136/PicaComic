part of 'components.dart';

extension ColorSchemeExt on ColorScheme {
  MaterialAccentColor findClosestColor() {
    var color = primary;
    var allColor = colors;
    var closestColor = allColor.first;
    var closestDistance = _calcDistance(color, closestColor);
    for (var c in allColor) {
      var distance = brightness == Brightness.light
        ? _calcDistance(color, c.shade700)
        : _calcDistance(color, c.shade200);
      if (distance < closestDistance) {
        closestColor = c;
        closestDistance = distance;
      }
    }
    return closestColor;
  }

  double _calcDistance(Color a, Color b) {
    return (math.pow(a.red - b.red, 2) +
            math.pow(a.green - b.green, 2) +
            math.pow(a.blue - b.blue, 2))
        .toDouble();
  }
}

extension AccentColorExt on MaterialAccentColor {
  Color toPrimary(Brightness brightness) {
    return brightness == Brightness.light ? shade700 : shade200;
  }

  Color toBackground(Brightness brightness) {
    return brightness == Brightness.light ? shade100 : shade700;
  }
}
