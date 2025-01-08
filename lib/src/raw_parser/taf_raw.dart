import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/tds_parser/forecast_tds.dart';
import 'dart:developer' as developer;
import 'forecast_raw.dart';

/// Taf content derived from raw text
class TafRaw {
  final String stationId;
  final DateTime issueTime;
  final List<Map<String, String?>> data;

  TafRaw(
      {required this.stationId, required this.issueTime, required this.data});

  factory TafRaw.fromMap(List<Map<String, String?>> data) {
    final tafData = data[0];
    final stationId = tafData['station'] ?? '';
    // published time set ore reconstructed from endurance start
    final issueTimeString = tafData['published'] ??
        "${tafData['endurance']?.substring(0, 4) ?? ""}00";
    final issueTime = _parseIssueTime(issueTimeString);
    // look for Taf appendix

    return TafRaw(
        stationId: stationId,
        issueTime: issueTime,
        // Assuming bulletinTime matches issueTime
        data: data);
  }

  /// raw taf of this parts
  late final String rawPart = data.map((e) => e.values.join(" ").trim()).join(' ');

  /// raw taf string of whole taf including the forecasts
  late String rawText = (forecasts.map((e) => e.rawPart.trim()).join(' '));

  static DateTime _parseIssueTime(String issueTimeString) {
    // Assuming the format is "ddhhmmZ"
    final now = DateTime.now().toUtc();
    final day = int.parse(issueTimeString.substring(0, 2));
    final hour = int.parse(issueTimeString.substring(2, 4));
    final minute = int.parse(issueTimeString.substring(4, 6));

    return DateTime.utc(now.year, now.month, day, hour, minute);
  }

  /// Sorting by fcstTimeFrom, then fcstTimeTo, then ChangeIndicator
  late final List<ForecastRaw> forecasts = (() {
    final List<ForecastRaw> list = List.from(data.map((e) => ForecastRaw.fromMap(e)));
    FlightCategory.calculateFlightCategories(list);
    return list;
  })();

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

