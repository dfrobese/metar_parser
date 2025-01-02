import 'dart:developer' as developer;
import 'package:country/country.dart';
import 'package:metar_parser_dart/src/Forecast.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/CloudStack.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';
import 'package:metar_parser_dart/src/raw_parser/taf_raw.dart';
import 'package:xml/xml.dart';

import 'PresentWeather.dart';


/// Taf content derived from NOAA text data server
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
  /// list of forecasts sorted by time
  late List<Forecast>forecasts = _buildForecasts();
  /// taf objects parsed from raw text
  late TafRaw _tafFromRaw = ((){
     final mapFromRaw = MetarTafRawParser.parseTafRawText(rawText);
     return TafRaw.fromMap(mapFromRaw);
   })();
  /// GPS coordinates of station
  late Coordinate coordinate =  Coordinate(latitude: latitude, longitude: longitude);

  /// Build forcecast from TDS and find the matching raw segment
  List<Forecast> _buildForecasts() {
    // create Taf from raw
    final tafTDS = tafElement.findElements('forecast').map((e) => Forecast.fromXml(e, _tafFromRaw)).toList();
    // sort by time and changeindicator
    tafTDS.sort((a, b) {
      int result = a.fcstTimeFrom.compareTo(b.fcstTimeFrom);
      if (result == 0) {
        result = -(a.fcstTimeTo.compareTo(b.fcstTimeTo));
      }
      if (result == 0) {
        result = a.changeIndicator.index.compareTo(b.changeIndicator.index);
      }
      return result;
    });
    return tafTDS;
  }


  late String rawFormatedText = forecasts.map((e) => e.forecastFromRaw?.rawPart).join("\n");
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
