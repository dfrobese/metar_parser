enum VelocityUnit {
  KT, MPS, KPH;

  static final List<String> unitStr = ["kt", "m/s", "km/h"];

  // Wind regexp
  static  final String regStr = VelocityUnit.values.map((e){return e.name;}).join("|");

  /// Create object from string
  factory VelocityUnit.parse(String str) {
    var cl = VelocityUnit.values.firstWhere((e) => e.name == str.toUpperCase(), orElse: () => VelocityUnit.KT);
    return cl;
  }

  String get unit {
    assert(this.index <= VelocityUnit.unitStr.length);
    return VelocityUnit.unitStr[this.index];
  }

  // Converts speed to knots based on the unit.
  int convertToKnots(int speed) {
    switch (this) {
      case KT: // Knots
        return speed;
      case MPS: // Meters per second
        return (speed * 1.94384).round();
      case KPH: // Kilometers per hour
        return (speed * 0.539957).round();
      default:
        throw ArgumentError('Unknown unit: $unit');
    }
  }
}
