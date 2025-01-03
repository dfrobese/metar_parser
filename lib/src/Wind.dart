
import 'package:xml/xml.dart';

enum WindUnit {
  KT, MPS, KPH;

  static final List<String> unitStr = ["kt", "m/s", "km/h"];

  // Wind regexp
  static  final String regStr = WindUnit.values.map((e){return e.name;}).join("|");

  /// Create object from string
  factory WindUnit.parse(String str) {
    var cl = WindUnit.values.firstWhere((e) => e.name == str.toUpperCase(), orElse: () => WindUnit.KT);
    return cl;
  }

  String get unit {
     assert(this.index <= WindUnit.unitStr.length);
     return WindUnit.unitStr[this.index];
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


class Wind {
  /// variable wind direction
  final bool variable;
  /// Wind direction in degrees
  final int direction;
  /// Wind direction min in degrees
  final int ?dir_from;
  /// Wind direction max in degrees
  final int ?dir_to;
  /// Wind speed in knots
  final int speed;
  /// Wind gusts in knots
  final int ?gust;

  /// Init wind
  const Wind(this.variable, this.direction, this.speed, [this.gust, this.dir_from , this.dir_to]);

  /// wind object from TDS XML expression
  factory Wind.fromElement(XmlElement metarElement) {
    var dirString = metarElement.getElement('wind_dir_degrees')?.innerText ?? "0";
    var variable = dirString == "VRB";
    var direction = variable ? 0 : int.tryParse(dirString) ?? 0;
    var speed = int.tryParse(metarElement.getElement('wind_speed_kt')?.innerText ?? "0") ?? 0;
    var gust = int.tryParse(metarElement.getElement('wind_gust_kt')?.innerText ?? "");
    return Wind(variable, direction, speed, gust);
  }

  /// wind from raw
  /// Parses a TAF wind string into a Wind object.
  factory Wind.from(String tafWindString) {
    final RegExp windRegex = RegExp(
    r'(?<variable>VRB)|(?<direction>\d{3})(?<speed>P?\d{2})(?:G(?<gust>P?\d{2}))?(?<unit>KT|MPS|KPH)(?: (?<dir_from>\d{3})V(?<dir_to>\d{3}))?',
    );

    final match = windRegex.firstMatch(tafWindString);

    if (match == null) {
       throw ArgumentError('Invalid TAF wind string: $tafWindString');
    }

    final isVariable = match.namedGroup('variable') != null;
    final direction = isVariable ? 0 : int.parse(match.namedGroup('direction')!);
    final speedGroup = match.namedGroup('speed')!;
    final gustGroup = match.namedGroup('gust');
    final dirFromGroup = match.namedGroup('dir_from');
    final dirToGroup = match.namedGroup('dir_to');
    final unitStr = match.namedGroup('unit')!;

    // Parse wind speed and gust values
    final speed = speedGroup.startsWith('P')
    ? int.parse(speedGroup.substring(1)) + 1
        : int.parse(speedGroup);
    final gust = gustGroup != null
    ? gustGroup.startsWith('P')
    ? int.parse(gustGroup.substring(1)) + 1
        : int.parse(gustGroup)
        : null;

    // Convert speed and gust to knots
    final unit = WindUnit.parse(unitStr);
    final speedKnots = unit.convertToKnots(speed);
    final gustKnots = gust != null ? unit.convertToKnots(gust) : null;

    // Parse directional variability
    final dirFrom = dirFromGroup != null ? int.parse(dirFromGroup) : null;
    final dirTo = dirToGroup != null ? int.parse(dirToGroup) : null;

    return Wind(isVariable, direction, speedKnots, gustKnots, dirFrom, dirTo);
  }



  /// Return true if gusty wind condition
  bool get isGusty => (gust != null && gust! > 0);

}