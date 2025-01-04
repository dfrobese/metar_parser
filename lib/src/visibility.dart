import 'package:metar_parser_dart/src/units/distance_unit.dart';

class Visibility {
  /// Minimum visibility
  final double minVisibility;

  /// Maximum visibility (if specified)
  final double? maxVisibility;

  /// Unit of visibility
  final DistanceUnit unit;

  /// Indicates if the visibility is "greater than" the minimum
  final bool isGreaterThanMin;

  /// Factory constructor to parse visibility from a TAF string
  factory Visibility.parse(String tafString) {
    final RegExp visibilityRegex = RegExp(
        r'(?<greaterThan>P?)' // Optional "P" for greater-than flag
        r'(?<miles>\d\s\d\/\d|\d\/\d|\d{1,2})' // Integer, fractional, or mixed miles
        r'(?<unit>SM)|(?<meters>\d{4})(?:\s(?<metersMax>\d{4}))?' // Meters with optional range
    );

    final match = visibilityRegex.firstMatch(tafString);

    if (match == null) {
      throw ArgumentError('Invalid visibility string: $tafString');
    }

    double? minVisibility;
    double? maxVisibility;
    DistanceUnit? unit;
    bool isGreaterThanMin = false;

    if (match.namedGroup('miles') != null) {
      unit = DistanceUnit.SM;

      final greaterThan = match.namedGroup('greaterThan');
      final miles = match.namedGroup('miles')!;

      if (greaterThan == "P") {
        isGreaterThanMin = true;
      }

      if (miles.contains(' ')) {
        // Mixed integer and fraction (e.g., "2 1/2")
        final parts = miles.split(' ');
        minVisibility = double.parse(parts[0]) + _parseFraction(parts[1]);
      } else if (miles.contains('/')) {
         // Fractional miles
         minVisibility = _parseFraction(miles);
       } else  {
        // Integer miles
        minVisibility = double.parse(miles);
      }
    } else if (match.namedGroup('meters') != null) {
      unit = DistanceUnit.M;

      final meters = double.parse(match.namedGroup('meters')!);
      minVisibility = meters;

      if (match.namedGroup('metersMax') != null) {
        maxVisibility = double.parse(match.namedGroup('metersMax')!);
      }
    } else {
      throw ArgumentError('Unable to determine visibility unit: $tafString');
    }

    return Visibility(minVisibility, unit, isGreaterThanMin, maxVisibility);
  }

  /// Constructor
  Visibility(this.minVisibility, this.unit, this.isGreaterThanMin, [this.maxVisibility]);

  /// Minimum visibility in miles
  double get minInMiles => unit == DistanceUnit.SM
      ? minVisibility
      : unit.convertToMiles(minVisibility);

  /// Maximum visibility in miles (if specified)
  double? get maxInMiles => maxVisibility == null
      ? null
      : unit == DistanceUnit.SM
      ? maxVisibility
      : unit.convertToMiles(maxVisibility!);

  @override
  String toString() {
    return 'Visibility(min: $minVisibility ${unit.unit}, max: ${maxVisibility ?? 'N/A'} ${unit.unit}, greaterThanMin: $isGreaterThanMin)';
  }

  /// Helper to parse a fraction string like "1/2" into a double
  static double _parseFraction(String fraction) {
    final parts = fraction.split('/');
    if (parts.length != 2) {
      throw ArgumentError('Invalid fraction: $fraction');
    }
    return double.parse(parts[0]) / double.parse(parts[1]);
  }
}
