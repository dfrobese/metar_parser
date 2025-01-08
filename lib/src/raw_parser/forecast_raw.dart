// Forecast as part of a TafTDS
import 'package:metar_parser_dart/src/visibility.dart';
import 'package:metar_parser_dart/src/wind.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';

import '../../metar_parser_dart.dart';
import '../cloud_stack.dart';
import '../tds_parser/forecast_tds.dart';
import '../present_weather.dart';

class ForecastRaw implements FlightCategoryRelated {
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
    var changeText = data[MetarRawElement.change_indicator.name] ?? 'TAF';
    // parse change indicator
    final map = _parseIndicator(changeText);
    // get change Indicator
    final changeIndicator = ChangeIndicator.parse(map["indicator"]!);
    // From indicator
    if (changeIndicator == ChangeIndicator.FM) {
      final from = _parseValidFrom(map["value"]!);
      return ForecastRaw(
          fcstTimeFrom: from,
          fcstTimeTo: from.add(Duration(hours: 12)), // interims setting
          changeIndicator: changeIndicator,
          probability: 100,
          data: data);
    }
    // the rest of
    // probability
    final probability = (map["value"] != null)
        ? int.parse(map["value"]!)
        : 100;
    // endurance
    final endurance = data[MetarRawElement.endurance.name] ?? '0000/0000';
    final validTimes = _parseValidTimes(endurance);

    return ForecastRaw(
        fcstTimeFrom: validTimes[0],
        fcstTimeTo: validTimes[1],
        changeIndicator: changeIndicator,
        probability: probability,
        data: data);
  }

  /// get wind parameters
  late final Wind? wind = Wind.parse("${data[MetarRawElement.windGusts.name]??""} ${data[MetarRawElement.windVaries.name]??""}".trim());
  /// weather text
  late final List<String>? _wx_list = (data[MetarRawElement.weatherTaf.name]??"").split(" ");
  /// Decoded weather or null if not reported
  late final List<PresentWeather>? weather = _wx_list != null ? _wx_list!.map((e) =>  PresentWeather.parse(e)).toList() : null;
  /// cloud information
  late final CloudStack sky_condition = CloudStack.fromRaw(data[MetarRawElement.clouds.name]??"");
  /// Horizontal visibility
  late final Visibility ?visibility = data[MetarRawElement.visibility.name] != null ? Visibility.parse(data[MetarRawElement.visibility.name]!) : null;
   /// raw String build from parsed parts
  late final String rawPart = data.entries
      .where((e) => e.key != "raw")
      .map((e) => e.value?.trim())
      .join(' ');

  /// raw string in whole
  String get raw => (data["raw"] ?? "").trim();

  /// parse for change indicator TAF|PROB|BECMG|TEMPO|INTER|FM
  static Map<String, String?> _parseIndicator(String text) {
    final pattern = RegExp(
        r'(?<indicator>(TAF|PROB|BECMG|TEMPO|INTER|FM))(?<value>(\d{2,6}))?(?<tempo>(\sTEMPO))?');
    final match = pattern  .firstMatch(text);

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

  static DateTime _parseValidFrom(String time) {
    // Assuming the format is "ddhhmm"
    final now = DateTime.now().toUtc();

    final fromDay = int.parse(time.substring(0, 2));
    final fromHour = int.parse(time.substring(2, 4));
    final fromMin = int.parse(time.substring(4, 6));


    final validTimeFrom = DateTime.utc(now.year, now.month, fromDay, fromHour, fromMin);


    return validTimeFrom;
  }
  /// Flightcategory related
  /// base AGL of lowest significant cloud in feet
  late final int? lowestSignificantCloudBase = this.sky_condition.lowestSignificantCloudBase;
  /// lowest visibility in miles
  late final double? lowestVisibility = visibility?.minInMiles;

  late FlightCategory flightCategory = FlightCategory.NONE;
}
