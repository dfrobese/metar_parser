
import 'package:xml/xml.dart';

enum WindUnit {
  KT, MPS, KPH;

  static final List<String> unitStr = ["kt", "m/s", "km/h"];

  // Wind regexp
  static  final String regStr = WindUnit.values.map((e){return e.name;}).join("|");

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
  /// Return true if gusty wind condition
  bool get isGusty => (gust != null && gust! > 0);


}