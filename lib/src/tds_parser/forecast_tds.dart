import 'package:metar_parser_dart/src/cloud_stack.dart';
import 'package:metar_parser_dart/src/present_weather.dart';
import 'package:metar_parser_dart/src/units/distance_unit.dart';
import 'package:metar_parser_dart/src/visibility.dart';
import 'package:metar_parser_dart/src/wind.dart';
import 'package:metar_parser_dart/src/raw_parser/forecast_raw.dart';
import 'package:metar_parser_dart/src/raw_parser/taf_raw.dart';
import 'package:xml/xml.dart';

import '../../metar_parser_dart.dart';

enum ChangeIndicator {
  METAR, TAF, FM, BECMG, PROB, TEMPO, INTER;

  /// Create object from string
  factory ChangeIndicator.parse(String str) {
    var cl = ChangeIndicator.values.firstWhere((e) => e.name == str.toUpperCase());
    return cl;
  }

}

/// Forecast as part of a TafTDS
class ForecastTDS implements FlightCategoryRelated {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final ChangeIndicator changeIndicator;
  final int probability;
  final XmlElement fcstElement;
  final ForecastRaw? forecastFromRaw;

  ForecastTDS({
    required this.fcstTimeFrom,
    required this.fcstTimeTo,
    required this.fcstElement,
    required this.changeIndicator,
    required this.probability,
    required this.forecastFromRaw
  });

  factory ForecastTDS.fromXml(XmlElement xml, TafRaw rawTaf) {
    final fcstTimeFrom = DateTime.parse(xml.getElement('fcst_time_from')?.innerText ?? DateTime.now().toString());
    final fcstTimeTo = DateTime.parse(xml.getElement('fcst_time_to')?.innerText ?? DateTime.now().toString());
    final probability = int.tryParse(xml.getElement('probability')?.innerText ?? '100') ?? 100;
    final changeIndicator = ChangeIndicator.parse(xml.getElement('change_indicator')?.innerText ?? 'TAF');
    final rawForecast = rawTaf.getBy(changeIndicator, fcstTimeFrom, fcstTimeTo);

    return ForecastTDS(
      fcstTimeFrom: fcstTimeFrom,
      fcstTimeTo: fcstTimeTo,
      fcstElement: xml,
      probability: probability,
      changeIndicator: changeIndicator,
      forecastFromRaw: rawForecast
    );
  }

  /// get wind parameters
  late final Wind wind = Wind.fromElement(fcstElement);
  /// weather text
  late final String? wx_string = fcstElement.getElement('wx_string')?.innerText;
  /// Decoded weather or null if not reported
  late final PresentWeather? weather = wx_string != null ? PresentWeather.parse(wx_string!) : null;
  /// cloud information
  late final CloudStack? sky_condition = CloudStack.fromElement(fcstElement);
  /// base AGL of lowest significant cloud
  late final int? lowestSignificantCloudBase = this.sky_condition?.lowestSignificantCloudBase??null;
  /// ambient pressure
  late final double altim_in_hg = double.parse(fcstElement.getElement('altim_in_hg')?.innerText ?? "0");
  /// tempertures
  late final double temp_c = double.parse(fcstElement.getElement('temp_c')?.innerText ?? "0");
  late final double dewpoint_c = double.parse(fcstElement.getElement('dewpoint_c')?.innerText ?? "0");
  /// internal visibility string
  late final String? _visibilityStr = fcstElement.getElement('visibility_statute_mi')?.innerText;
  /// visibility status miles
  late final Visibility? visibility = (() {
    if (_visibilityStr != null) {
      // if an string exists, parse it
      var match = RegExp( r'(?<miles>\d{1,2}(\.\d{1,2})?)(?<greater>\+)?' ).firstMatch(_visibilityStr!);
      if (match != null && match.namedGroup('miles') != null) {
        final value = double.parse(match.namedGroup('miles')!);
        final greater = match.namedGroup('greater') != null;
        return Visibility(value, DistanceUnit.SM, greater);
      }
    } else if (this.changeIndicator == ChangeIndicator.TAF) {
      // default on TAF beginning if no value is given
      return Visibility(6.0, DistanceUnit.SM, true);
    }
    return null;
  })();
  /// lowest visibility in miles
  late final double? lowestVisibility = visibility?.minInMiles;
  /// preset
  late FlightCategory flightCategory = FlightCategory.calc(this);
}