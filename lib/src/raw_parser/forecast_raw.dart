// Forecast as part of a TafTDS
import 'package:metar_parser_dart/src/Wind.dart';

import '../CloudStack.dart';
import '../Forecast.dart';
import '../PresentWeather.dart';

class ForecastRaw {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final ChangeIndicator changeIndicator;
  final int probability;
  final Map<String, String?> data;

  ForecastRaw(
      {required this.fcstTimeFrom,
        required this.fcstTimeTo,
        required this.changeIndicator,
        required this.probability,
        required this.data});

  factory ForecastRaw.fromMap(Map<String, String?> data) {
    var changeText = data['change_indicator'] ?? 'TAF';
    // parse change indicator
    final map = _parseIndicator(changeText);
    // get change Indicator
    final changeIndicator = ChangeIndicator.parse(map["indicator"]!);
    // probability
    final probability =
    (map["value"] != null && changeIndicator != ChangeIndicator.FM)
        ? int.parse(map["value"]!)
        : 100;
    // endurance
    var endurance = data['endurance'] ?? '0000/0000';
    // use for FM star time and 0000
    if (changeIndicator == ChangeIndicator.FM) {
      endurance = "${map["value"]?.substring(0, 4)}/0000";
    }
    final validTimes = _parseValidTimes(endurance);

    return ForecastRaw(
        fcstTimeFrom: validTimes[0],
        fcstTimeTo: validTimes[1],
        changeIndicator: changeIndicator,
        probability: probability,
        data: data);
  }

  /// get wind parameters
  // Todo: late Wind wind = Wind.fromElement(fcstElement);
  /// weather text
  late String? wx_string = data['wx_string'];
  /// Decoded weather or null if not reported
  late PresentWeather? weather = wx_string != null ? PresentWeather.parse(wx_string!) : null;

  /// cloud information
  late CloudStack sky_condition = CloudStack.fromRaw(data['clouds']??"");
  /// base AGL of lowest significant cloud
  late int? lowestSignificantCloudBase = this.sky_condition.lowestSignificantCloudBase;

  /// raw String build from parsed parts
  late String rawPart = data.entries
      .where((e) => e.key != "raw")
      .map((e) => e.value?.trim())
      .join(' ');

  /// raw string in whole
  String get raw => (data["raw"] ?? "").trim();

  static Map<String, String?> _parseIndicator(String text) {
    final pattern = RegExp(
        r'(?<indicator>(TAF|PROB|BECMG|TEMPO|INTER|FM))(?<value>(\d{2,6}))?(?<tempo>(\sTEMPO))?');

    final match = pattern.firstMatch(text);

    if (match != null) {
      // Extract named groups
      final tempo = match.namedGroup('tempo');
      final result = {
        'indicator':
        tempo != null ? tempo.trim() : match.namedGroup('indicator'),
        // Matches the indicator alone (e.g., PROB, BECMG, TEMPO, FM)
        'value': match.namedGroup('value'),
      };

      return result;
      // Example Output for "PROB30 TEMPO": {indicator: PROB}
    }
    return {};
  }

  static List<DateTime> _parseValidTimes(String endurance) {
    // Assuming the format is "ddhh/ddhh"
    final now = DateTime.now().toUtc();

    final fromDay = int.parse(endurance.substring(0, 2));
    final fromHour = int.parse(endurance.substring(2, 4));
    final toDay = int.parse(endurance.substring(5, 7));
    final toHour = int.parse(endurance.substring(7, 9));

    final validTimeFrom = DateTime.utc(now.year, now.month, fromDay, fromHour);
    final validTimeTo = DateTime.utc(now.year, now.month, toDay, toHour);

    return [validTimeFrom, validTimeTo];
  }
}
