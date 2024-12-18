import 'package:metar_parser_dart/src/Forecast.dart';

/// Taf content derived from raw text
class TafRaw  {
  final String stationId;
  final DateTime issueTime;
  final List<ForecastRaw> forecasts;
  final String tail;
  final Map<String, String?> data;

  TafRaw({
    required this.stationId,
    required this.issueTime,
    required this.forecasts,
    required this.tail,
    required this.data
  });


  factory TafRaw.fromMap(List<Map<String, String?>> data) {
    final tafData = data[0];
    final stationId = tafData['station'] ?? '';
    // published time set ore reconstructed from endurance start
    final issueTimeString = tafData['published'] ?? "${tafData['endurance']?.substring(0,4)?? ""}00";
    final issueTime = _parseIssueTime(issueTimeString);
     final parts = data.sublist(0, data.length-1);
    final forecasts = parts.map((e) => ForecastRaw.fromMap(e));
    final tail = data[data.length-1].entries.map((e) => "${e.value}").join(' ');

    return TafRaw(
        stationId: stationId,
        issueTime: issueTime,
        // Assuming bulletinTime matches issueTime
        forecasts: forecasts.toList(),
        tail: tail,
        data: tafData
    );
   }
   /// raw taf of this part
  late String rawPart = data.entries.map((e) => "${e.value}").join(' ');
  /// raw taf string of whole taf including the forecasts
  late String rawText = (forecasts.map((e) =>e.rawPart).join(' ') + " ${tail}").trim();
  
  static DateTime _parseIssueTime(String issueTimeString) {
    // Assuming the format is "ddhhmmZ"
    final now = DateTime.now().toUtc();
    final day = int.parse(issueTimeString.substring(0, 2));
    final hour = int.parse(issueTimeString.substring(2, 4));
    final minute = int.parse(issueTimeString.substring(4, 6));

    return DateTime.utc(now.year, now.month, day, hour, minute);
  }
}

// Forecast as part of a TafTDS
class ForecastRaw {
  final DateTime fcstTimeFrom;
  final DateTime fcstTimeTo;
  final ChangeIndicator changeIndicator;
  final int probability;
  final Map<String, String?> data;

  ForecastRaw({
    required this.fcstTimeFrom,
    required this.fcstTimeTo,
    required this.changeIndicator,
    required this.probability,
    required this.data
  });

  factory ForecastRaw.fromMap(Map<String, String?> data) {
    var changeText = data['change_indicator']?? 'TAF';
    // parse change indicator
    final map = _parseIndicator(changeText);
    // get change Indicator
    final changeIndicator = ChangeIndicator.parse(map["indicator"]!);
    // probability
    final probability = (map["value"] != null && changeIndicator != ChangeIndicator.FM) ? int.parse(map["value"]!) : 100;
    // endurance
    var endurance = data['endurance'] ?? '0000/0000';
    // use for FM star time and 0000
    if  (changeIndicator == ChangeIndicator.FM) {
      endurance = "${map["value"]?.substring(0,4)}/0000";
    }
    final validTimes = _parseValidTimes(endurance);

     return ForecastRaw(
        fcstTimeFrom: validTimes[0],
        fcstTimeTo: validTimes[1],
        changeIndicator: changeIndicator,
        probability: probability,
        data: data
    );
  }
  late String rawPart = data.entries.map((e) => "${e.value}").join(' ');

  static Map<String, String?> _parseIndicator(String text) {
    final pattern = RegExp(
        r'(?<indicator>(TAF|PROB|BECMG|TEMPO|FM))(?<value>(\d{2,6}))?(?<tempo>(\sTEMPO))?'
    );

    final match = pattern.firstMatch(text);

    if (match != null) {
      // Extract named groups
      final tempo = match.namedGroup('tempo');
      final result = {
        'indicator': tempo != null ? tempo : match.namedGroup('indicator'), // Matches the indicator alone (e.g., PROB, BECMG, TEMPO, FM)
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
