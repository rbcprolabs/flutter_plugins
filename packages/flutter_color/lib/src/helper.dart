import 'dart:ui' show Color;

extension ColorHelper on Color {
  /// Make color lighter by so many [percents]
  Color lighter(int percents) {
    assert(percents >= 1 && percents <= 100);
    final int rgbPercent = (percents / 100 * 255).round();
    int red = this.red + rgbPercent,
        green = this.green + rgbPercent,
        blue = this.blue + rgbPercent;
    if (red > 255) {
      red = 255;
    }
    if (green > 255) {
      green = 255;
    }
    if (blue > 255) {
      blue = 255;
    }
    return Color.fromARGB(alpha, red, green, blue);
  }

  /// Make color darker by so many [percents]
  Color darker(int percents) {
    assert(percents >= 1 && percents <= 100);
    final int rgbPercent = (percents / 100 * 255).round();
    int red = this.red - rgbPercent,
        green = this.green - rgbPercent,
        blue = this.blue - rgbPercent;
    if (red < 0) {
      red = 0;
    }
    if (green < 0) {
      green = 0;
    }
    if (blue < 0) {
      blue = 0;
    }
    return Color.fromARGB(alpha, red, green, blue);
  }

  /// Linearly interpolate between two colors.
  ///
  /// This is intended to be fast but as a result may be ugly. Consider
  /// HSVColor or writing custom logic for interpolating colors.
  ///
  /// If either color is null, this function linearly interpolates from a
  /// transparent instance of the other color. This is usually preferable to
  /// interpolating from [material.Colors.transparent] (`const
  /// Color(0x00000000)`), which is specifically transparent _black_.
  ///
  /// The `t` argument represents position on the timeline, with 0.0 meaning
  /// that the interpolation has not started, returning `a` (or something
  /// equivalent to `a`), 1.0 meaning that the interpolation has finished,
  /// returning `b` (or something equivalent to `b`), and values in between
  /// meaning that the interpolation is at the relevant point on the timeline
  /// between `a` and `b`. The interpolation can be extrapolated beyond 0.0 and
  /// 1.0, so negative values and values greater than 1.0 are valid (and can
  /// easily be generated by curves such as Curves.elasticInOut). Each channel
  /// will be clamped to the range 0 to 255.
  ///
  /// Values for `t` are usually obtained from an [Animation<double>], such as
  /// an AnimationController.
  Color? mix(Color another, double amount) => Color.lerp(this, another, amount);

  /// Convert color to hex string
  String get asHexString => '#' + value.toRadixString(16).toUpperCase();
}
