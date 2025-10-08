
import 'package:country/country.dart';
import 'package:metar_parser_dart/src/tds_parser/forecast_tds.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:xml/xml.dart';
import '../../metar_parser_dart.dart';


/// Taf content derived from NOAA text data server
class TafTDS extends TDSElement {
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
  late final double elevationM = double.parse(tafElement.getElement('elevation_m')?.innerText ?? '0');
  /// list of forecasts sorted by time
  late final List<ForecastTDS>forecasts = _buildForecasts();
  /// taf objects parsed from raw text
  ///late final TafRaw _tafFromRaw = TafRaw.parse(rawText);
  /// GPS coordinates of station
  late final Coordinate coordinate = Coordinate(latitude: latitude, longitude: longitude);

  /// Build forcecast from TDS and find the matching raw segment
  List<ForecastTDS> _buildForecasts() {
    // create Taf from raw
    final tafTDS = tafElement.findElements('forecast').map((e) => ForecastTDS.fromXml(e)).toList();
    // sort by time and changeindicator
    tafTDS.sort((a, b) {
      if (a.changeIndicator == ChangeIndicator.TAF) {
        return -1;
      }
      int result = a.fcstTimeFrom.compareTo(b.fcstTimeFrom);
      if (result == 0) {
        result = a.changeIndicator.index.compareTo(b.changeIndicator.index);
      }
      if (result == 0) {
        result = -(a.fcstTimeTo.compareTo(b.fcstTimeTo));
      }
      return result;
    });
    //
    FlightCategory.calculateFlightCategories(tafTDS);
    return tafTDS;
  }

}


