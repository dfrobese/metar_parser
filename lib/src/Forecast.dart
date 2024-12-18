import 'package:metar_parser_dart/src/CloudStack.dart';
import 'package:metar_parser_dart/src/PresentWeather.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:xml/xml.dart';

enum ChangeIndicator {
  TAF, BECMG, TEMPO, PROB, FM, INTER;

  /// Create object from string
  factory ChangeIndicator.parse(String str) {
    var cl = ChangeIndicator.values.firstWhere((e) => e.name == str.toUpperCase());
    return cl;
  }
}

/// Forecast as part of a TafTDS
class Forecast {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final ChangeIndicator changeIndicator;
  final int probability;
  final XmlElement fcstElement;

  Forecast({
    required this.fcstTimeFrom,
    required this.fcstTimeTo,
    required this.fcstElement,
    required this.changeIndicator,
    required this.probability,
  });

  factory Forecast.fromXml(XmlElement xml) {
    return Forecast(
      fcstTimeFrom: DateTime.parse(xml.getElement('fcst_time_from')?.innerText ?? DateTime.now().toString()),
      fcstTimeTo: DateTime.parse(xml.getElement('fcst_time_to')?.innerText ?? DateTime.now().toString()),
      fcstElement: xml,
      probability: int.tryParse(xml.getElement('probability')?.innerText ?? '100') ?? 100,
      changeIndicator: ChangeIndicator.parse(xml.getElement('change_indicator')?.innerText ?? 'TAF'),

    );
  }

  /// get wind parameters
  late Wind wind = Wind.fromElement(fcstElement);
  /// weather text
  late String? wx_string = fcstElement.getElement('wx_string')?.innerText;
  /// Decoded weather or null if not reported
  late PresentWeather? weather = wx_string != null ? PresentWeather.parse(wx_string!) : null;
  /// cloud information
  late CloudStack sky_condition = CloudStack.fromElement(fcstElement);
  /// base AGL of lowest significant cloud
  late double? lowestSignificantCloudBase = this.sky_condition.lowestSignificantCloudBase;
  /// ambient pressure
  late double altim_in_hg = double.parse(fcstElement.getElement('altim_in_hg')?.innerText ?? "0");
  /// tempertures
  late double temp_c = double.parse(fcstElement.getElement('temp_c')?.innerText ?? "0");
  late double dewpoint_c = double.parse(fcstElement.getElement('dewpoint_c')?.innerText ?? "0");
  /// internal visibility string
  late String? _visibilityStr = fcstElement.getElement('visibility_statute_mi')?.innerText;
  /// visibility status miles
  late double? visibility_statute_mi = (() {
    if (_visibilityStr != null) {
      var match = RegExp(r'\d+').firstMatch(_visibilityStr!);
      if (match != null && match[0] != null) {
        return double.parse(match[0]!);
      }
    }
    return null;
  })();
  /// horizontal visibility in always in status miles
  double? get visibility => this.visibility_statute_mi;
}