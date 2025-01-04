enum DistanceUnit {
  SM, M;

  static final List<String> unitStr = ["SM", "m"];

  // Regex for distance unit
  static final String regStr = DistanceUnit.values.map((e) => e.name).join("|");

  /// Create object from string
  factory DistanceUnit.parse(String str) {
    return DistanceUnit.values.firstWhere(
          (e) => e.name.toUpperCase() == str.toUpperCase(),
      orElse: () => DistanceUnit.M, // Default to meters
    );
  }

  /// Returns unit string representation
  String get unit {
    assert(this.index < DistanceUnit.unitStr.length);
    return DistanceUnit.unitStr[this.index];
  }

  /// Converts distance to meters based on the unit.
  double convertToMeters(double distance) {
    switch (this) {
      case SM: // Statute miles
        return distance * 1609.34;
      case M: // Meters
        return distance;
      default:
        throw ArgumentError('Unknown unit: $unit');
    }
  }

  /// Converts distance to miles based on the unit.
  double convertToMiles(double distance) {
    switch (this) {
      case SM: // Statute miles
        return distance;
      case M: // Meters
        return distance / 1609.34;
      default:
        throw ArgumentError('Unknown unit: $unit');
    }
  }
}