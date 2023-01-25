
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
  double direction;
  /// Wind direction min in degrees
  double dir_from = 0;
  /// Wind direction max in degrees
  double dir_to = 0;
  /// Wind speed in knots
  double speed;
  /// Wind gusts in knots
  double gust = 0;

  Wind(this.direction, this.speed);



}