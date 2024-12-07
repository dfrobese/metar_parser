import 'dart:developer' as developer;
import 'package:country/country.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/CloudStack.dart';
import 'package:xml/xml.dart';

import 'PresentWeather.dart';


class TafTDS implements TDSElement{
  final String rawText;
  final String stationId;
  final DateTime issueTime;
  final DateTime bulletinTime;
  final DateTime validTimeFrom;
  final DateTime validTimeTo;
  final double latitude;
  final double longitude;
  final XmlElement tafElement;

  TafTDS({
    required this.rawText,
    required this.stationId,
    required this.issueTime,
    required this.bulletinTime,
    required this.validTimeFrom,
    required this.validTimeTo,
    required this.latitude,
    required this.longitude,
    required this.tafElement
  });

  factory TafTDS.fromXml(XmlElement xml) {
    return TafTDS(
      rawText: xml.getElement('raw_text')?.innerText ?? '',
      stationId: xml.getElement('station_id')?.innerText ?? '',
      issueTime: DateTime.parse(xml.getElement('issue_time')?.innerText ?? ''),
      bulletinTime: DateTime.parse(xml.getElement('bulletin_time')?.innerText ?? DateTime.now().toString()),
      validTimeFrom: DateTime.parse(xml.getElement('valid_time_from')?.innerText ?? DateTime.now().toString()),
      validTimeTo: DateTime.parse(xml.getElement('valid_time_to')?.innerText ?? DateTime.now().toString()),
      latitude: double.parse(xml.getElement('latitude')?.innerText ?? '0'),
      longitude: double.parse(xml.getElement('longitude')?.innerText ?? '0'),
      tafElement: xml
    );
  }
  /// Station ID ICAO 4 letter
  @override String get station_id => stationId;
  late double elevationM = double.parse(tafElement.getElement('elevation_m')?.innerText ?? '0');
  late List<Forecast>forecasts =  tafElement.findElements('forecast').map((e) => Forecast.fromXml(e)).toList();

  /// GPS coordinates of station
  late Coordinate coordinate =  Coordinate(latitude: latitude, longitude: longitude);
}

class Forecast {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final String? changeIndicator;
  final int? probability;
  final XmlElement fcstElement;

  Forecast({
    required this.fcstTimeFrom,
    required this.fcstTimeTo,
    required this.fcstElement,
    this.changeIndicator,
    this.probability,
  });

  factory Forecast.fromXml(XmlElement xml) {
    return Forecast(
      fcstTimeFrom: DateTime.parse(xml.getElement('fcst_time_from')?.innerText ?? DateTime.now().toString()),
      fcstTimeTo: DateTime.parse(xml.getElement('fcst_time_to')?.innerText ?? DateTime.now().toString()),
      fcstElement: xml,
      probability: int.tryParse(xml.getElement('probability')?.innerText ?? ''),
      changeIndicator: xml.getElement('change_indicator')?.innerText,

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

class Temperature {
  final DateTime validTime;
  final int? maxTempC;
  final int? minTempC;

  Temperature({
    required this.validTime,
    this.maxTempC,
    this.minTempC,
  });

  factory Temperature.fromXml(XmlElement xml) {
    return Temperature(
      validTime: DateTime.parse(xml.getElement('valid_time')?.innerText ?? ''),
      maxTempC: int.tryParse(xml.getElement('max_temp_c')?.innerText ?? ''),
      minTempC: int.tryParse(xml.getElement('min_temp_c')?.innerText ?? ''),
    );
  }
}
