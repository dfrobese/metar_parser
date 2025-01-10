import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';
import 'package:metar_parser_dart/src/tds_parser/forecast_tds.dart';
import 'dart:developer' as developer;
import 'forecast_raw.dart';
import '../extension/date_time.dart';

/// Taf content derived from raw text
class TafRaw {
  final String stationId;
  final DateTime issueTime;
  final List<Map<String, String?>> data;

  TafRaw._(
      {required this.stationId, required this.issueTime, required this.data});

  /// create TafRaw object from given list of maps
  factory TafRaw._fromMap(List<Map<String, String?>> data) {
    // first entry includes the taf header followed bei forecast groups
    final tafData = data[0];
    final stationId = tafData[MetarTafRawElement.station.name] ?? '';
    // published time set or reconstructed time from endurance start
    final enduranceString = "${tafData[MetarTafRawElement.endurance.name]?.substring(0, 4) ?? " "}";
    final issueTimeString = tafData[MetarTafRawElement.published.name] ?? "${enduranceString}00";
    final issueTime = DateTimeExtension.parseIssueTime(issueTimeString);

    return TafRaw._(
        stationId: stationId,
        issueTime: issueTime,
        // Assuming bulletinTime matches issueTime
        data: data);
  }

  /// Parse a raw Taf string and give back a TafRaw object
  factory TafRaw.parse(String rawText) {
    final mapFromRaw = MetarTafRawParser.parseTafRawText(rawText);
    return TafRaw._fromMap(mapFromRaw);
  }


  /// raw taf of this parts
  late final String rawPart = data.map((e) => e.values.join(" ").trim()).join(' ');

  /// raw taf string of whole taf including the forecasts
  late final String rawText = (forecasts.map((e) => e.rawPart.trim()).join(' '));


  /// Sorted list of forecasts by fcstTimeFrom, then fcstTimeTo, then ChangeIndicator
  late final List<ForecastRaw> forecasts = (() {
    final List<ForecastRaw> list = List.from(data.map((e) => ForecastRaw.fromMap(e)));
    FlightCategory.calculateFlightCategories(list);
    return list;
  })();

  /// get Taf from list by change indicator, and date time
  ForecastRaw? getBy(ChangeIndicator change, DateTime from, DateTime to) {
      try {
        if (change == ChangeIndicator.TAF || change == ChangeIndicator.FM || change == ChangeIndicator.BECMG) {
                 return forecasts.firstWhere( (forecast) =>
                    forecast.changeIndicator == change &&
                    forecast.fcstTimeFrom == from,
                    orElse: null,);
              }
        // treat TEMP and INTER like the same, a TDS bug
        if (change == ChangeIndicator.TEMPO || change == ChangeIndicator.INTER) {
                return forecasts.firstWhere(
                      (forecast) =>
                      (forecast.changeIndicator == ChangeIndicator.TEMPO || forecast.changeIndicator == ChangeIndicator.INTER) &&
                      forecast.fcstTimeFrom == from && forecast.fcstTimeTo == to,
                  orElse: null,);
              }
        // all other
        return forecasts.firstWhere(
                  (forecast) =>
                  forecast.changeIndicator == change &&
              forecast.fcstTimeFrom == from &&
                  forecast.fcstTimeTo == to,
              orElse: null,);
      } catch (e) {
        developer.log("ERROR: no corresponding TAF part found $change $from $to");
        return null;
      }
  }
}

