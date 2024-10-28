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
  final double elevationM;
  final List<Forecast> forecasts;

  TafTDS({
    required this.rawText,
    required this.stationId,
    required this.issueTime,
    required this.bulletinTime,
    required this.validTimeFrom,
    required this.validTimeTo,
    required this.latitude,
    required this.longitude,
    required this.elevationM,
    required this.forecasts,
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
      elevationM: double.parse(xml.getElement('elevation_m')?.innerText ?? '0'),
      forecasts: xml.findElements('forecast').map((e) => Forecast.fromXml(e)).toList(),
    );
  }
  /// Station ID ICAO 4 letter
  @override String get station_id => stationId;

  /// GPS coordinates of station
  late Coordinate coordinate =  Coordinate(latitude: latitude, longitude: longitude);
}

class Forecast {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final String? changeIndicator;
  final int? probability;
  final double? windDirDegrees;
  final double? windSpeedKt;
  final double? windGustKt;
  final double? visibilityStatuteMi;
  final double? altimInHg;
  final String? wxString;
  final CloudStack skyConditions;
  final List<Temperature>? temperatures;

  /// Wind information in one object
  late Wind? wind = (windGustKt != null && windSpeedKt != null && windDirDegrees != null) ?
                    Wind(windSpeedKt!, windDirDegrees!, windGustKt!) :
                    ((windSpeedKt != null && windDirDegrees != null) ? Wind(windSpeedKt!, windDirDegrees!) : null);

  Forecast({
    required this.fcstTimeFrom,
    required this.fcstTimeTo,
    this.changeIndicator,
    this.probability,
    this.windDirDegrees,
    this.windSpeedKt,
    this.windGustKt,
    this.visibilityStatuteMi,
    this.altimInHg,
    this.wxString,
    required this.skyConditions,
    this.temperatures,
  });

  factory Forecast.fromXml(XmlElement xml) {
    // scan degrees of wind
    var degrees = xml.getElement('wind_dir_degrees')?.innerText ?? "0";
    // decode visibility
    var visibility_statute_mi = null;
    var visibilityStr = xml.getElement('visibility_statute_mi')?.innerText;
    if (visibilityStr != null) {
      var match = RegExp(r'\d+').firstMatch(visibilityStr);
      if (match != null && match[0] != null) {
        visibility_statute_mi = double.parse(match[0]!);
      }
    }

    return Forecast(
      fcstTimeFrom: DateTime.parse(xml.getElement('fcst_time_from')?.innerText ?? DateTime.now().toString()),
      fcstTimeTo: DateTime.parse(xml.getElement('fcst_time_to')?.innerText ?? DateTime.now().toString()),
      probability: int.tryParse(xml.getElement('probability')?.innerText ?? ''),
      changeIndicator: xml.getElement('change_indicator')?.innerText,
      windDirDegrees: degrees == "VRB" ? 0.0 : double.parse(degrees),
      windSpeedKt: double.tryParse(xml.getElement('wind_speed_kt')?.innerText ?? '0') ?? 0,
      windGustKt: double.tryParse(xml.getElement('wind_gust_kt')?.innerText ?? '0') ?? 0,
      visibilityStatuteMi: visibility_statute_mi,
      altimInHg: double.tryParse(xml.getElement('altim_in_hg')?.innerText ?? ''),
      wxString: xml.getElement('wx_string')?.innerText,
      skyConditions: CloudStack.fromElement(xml),
      temperatures: xml.findElements('temperature').map((e) => Temperature.fromXml(e)).toList(),
    );
  }
  /// horizontal visibility in status miles
  double? get visibility => this.visibilityStatuteMi;
  /// Decoded weather or null if not reported
  late PresentWeather? weather = wxString != null ? PresentWeather.parse(wxString!) : null;
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
