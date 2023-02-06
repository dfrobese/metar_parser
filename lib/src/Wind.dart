
enum WindUnit {
  KT, MPS, KPH;

  static final List<String> unitStr = ["kt", "m/s", "km/h"];

  /// Create object from string
  factory WindUnit.parse(String str) {
    var cl = WindUnit.values.firstWhere((e) => e.name == str.toUpperCase());
    return cl;
  }

  String get unit {
     assert(this.index <= WindUnit.unitStr.length);
     return WindUnit.unitStr[this.index];
  }
}


class Wind {
  /// Wind direction in degrees
  final double direction;
  /// Wind direction min in degrees
  final double ?dir_from;
  /// Wind direction max in degrees
  final double ?dir_to;
  /// Wind speed in knots
  final double speed;
  /// Wind gusts in knots
  final double gust;

  const Wind(this.direction, this.speed, this.gust, [this.dir_from , this.dir_to]);

  /// Return true if gusty wind condition
  bool get isGusty => gust > 0;
  /// Return variable or not
  bool get isVariable => direction == 0;
}