// Forecast as part of a TafTDS
import 'package:metar_parser_dart/src/extension/date_time.dart';
import 'package:metar_parser_dart/src/visibility.dart';
import 'package:metar_parser_dart/src/wind.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';
import '../../metar_parser_dart.dart';
import '../cloud_coverage.dart';
import '../cloud_stack.dart';
import '../rvr.dart';
import '../tds_parser/forecast_tds.dart';
import '../present_weather.dart';
import '../units/distance_unit.dart';

/// Class defines a forecast in a raw TAF message
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

  /// create forecast object from a given key/value map created by the parser
  factory ForecastRaw.fromMap(Map<String, String?> data) {
    var changeText = data[MetarTafRawElement.change_indicator.name] ?? 'TAF';
    // parse change indicator
    final map = _parseIndicator(changeText);
    // get change Indicator
    final changeIndicator = ChangeIndicator.parse(map["indicator"]!);
    // From indicator
    if (changeIndicator == ChangeIndicator.FM) {
      final from = DateTimeExtension.parseIssueTime(map["value"]!);
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
    final endurance = data[MetarTafRawElement.endurance.name] ?? '0000/0000';
    final validTimes = DateTimeExtension.parseValidTimes(endurance);

    return ForecastRaw(
        fcstTimeFrom: validTimes[0],
        fcstTimeTo: validTimes[1],
        changeIndicator: changeIndicator,
        probability: probability,
        data: data);
  }

  /// get wind parameters
  late final Wind? wind = Wind.parse("${data[MetarTafRawElement.windGusts.name]??""} ${data[MetarTafRawElement.windVaries.name]??""}".trim());
  /// weather text
  late final List<String>? _wx_list = (data[MetarTafRawElement.weatherTaf.name]??"").split(" ");
  /// Decoded weather or null if not reported
  late final List<PresentWeather>? weather = _wx_list != null ? _wx_list!.map((e) =>  PresentWeather.parse(e)).toList() : null;
  /// cloud information
  late final CloudStack ?sky_condition = _parseCloudStack(data[MetarTafRawElement.clouds.name]);
  /// Horizontal visibility
  late final Visibility ?visibility =  _parseVisibility(data[MetarTafRawElement.visibility.name]);

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

  /// parse visibilty
  Visibility? _parseVisibility(String? raw) {
    if  (raw == "////")  {
      return null;
    } else if (raw != null) {
      return Visibility.parse(raw);
    } else if (this.changeIndicator == ChangeIndicator.TAF) {
      // default on TAF beginning if no value is given
      return Visibility(6.0, DistanceUnit.SM, true);
    } else if (sky_condition != null && sky_condition!.length > 0 && sky_condition!.first.coverage == CloudCoverage.CAVOK) {
      // if CAVOK set to P6SM
      return Visibility(6.0, DistanceUnit.SM, true);
    }
    return null;
  }

  CloudStack? _parseCloudStack(String? raw) {
    if (raw != null) {
      return CloudStack.fromRaw(raw);
    } else if (this.changeIndicator == ChangeIndicator.TAF) {
    // default on TAF beginning if no value is given
       return CloudStack.fromRaw(CloudCoverage.SKC.name);
    }
    return null;
  }

  /// Flightcategory related
  /// base AGL of lowest significant cloud in feet
  late final int? lowestSignificantCloudBase = this.sky_condition?.lowestSignificantCloudBase??null;
  /// lowest visibility in miles
  late final double? lowestVisibility =  this.visibility?.minInMiles ??null;
  /// flight category, preset is calcutalion based on current values
  late FlightCategory flightCategory = FlightCategory.calc(this);
  ///  RVR
  late final List<RVR?>? rvr = RVR.parseRVR(data[MetarTafRawElement.rvr.name]);

}

