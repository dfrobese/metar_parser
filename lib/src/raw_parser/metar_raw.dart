
import 'package:metar_parser_dart/src/cloud_coverage.dart';
import '../../metar_parser_dart.dart';
import '../cloud_stack.dart';
import '../present_weather.dart';
import '../tds_parser/forecast_tds.dart';
import '../units/distance_unit.dart';
import '../visibility.dart';
import '../wind.dart';
import 'metar_raw_parser.dart';
import '../extension/date_time.dart';

class MetarRaw implements FlightCategoryRelated {

  String station_id;
  DateTime observation_time; //2022-11-10T15:04:00Z
  final Map<String, String?> data;

  MetarRaw._(this.station_id, this.observation_time, this.data);

  /// create TafRaw object from given list of maps
  factory MetarRaw._fromMap(Map<String, String?> data) {
    // first entry includes the taf header followed bei forecast groups
    final metardata = data;
    final stationId = metardata[MetarTafRawElement.station.name] ?? '';
    // published time set ore reconstructed from endurance start
    final issueTimeString = metardata[MetarTafRawElement.published.name] ?? DateTime.now().toString();
    final issueTime = DateTimeExtension.parseIssueTime(issueTimeString);
    // look for Taf appendix

    return MetarRaw._(stationId, issueTime, metardata);
  }
  /// Parse a raw Taf string and give back a TafRaw object
  factory MetarRaw.parse(String rawText) {
    final mapFromRaw = MetarRaw._parseMetarRawText(rawText);
    return MetarRaw._fromMap(mapFromRaw);
  }

  /// Parese a raw Metar text and give back a map of items found
  static Map<String, String?> _parseMetarRawText(String metar) {
    Map<String, String?> parsedMetar = {"raw": metar.trim()};
    String remaining = metar + "\n"; // Add CR als end marker
    for (var element in MetarTafRawElement.metarSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0) {
        parsedMetar[element.name] = match.group(0)?.trim();
        remaining =
            remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    // Exit if no match is found in current remaining string
    return parsedMetar;
  }

  /// raw string in whole
  String get raw => (data["raw"] ?? "").trim();

  /// get wind parameters
  late final Wind? wind = Wind.parse("${data[MetarTafRawElement.windGusts.name]??""} ${data[MetarTafRawElement.windVaries.name]??""}".trim());
  /// weather text
  late final List<String>? _wx_list = (data[MetarTafRawElement.weatherMetar.name]??"").split(" ");
  /// Decoded weather or null if not reported
  late final List<PresentWeather>? weather = _wx_list != null ? _wx_list!.map((e) =>  PresentWeather.parse(e)).toList() : null;
  /// cloud information
  late final CloudStack ?sky_condition = CloudStack.fromRaw(data[MetarTafRawElement.clouds.name]??CloudCoverage.SKC.name); // parsed value or SKC as default
  /// Horizontal visibility
  late final Visibility ?visibility =  _parseVisibility(data[MetarTafRawElement.visibility.name]);

  /// parse visibilty
  Visibility? _parseVisibility(String? raw) {
    if  (raw == "////")  {
      return null;
    } else if(raw != null) {
      return Visibility.parse(raw);
    } else {
      // default on METAR beginning if no value is given
      return Visibility(6.0, DistanceUnit.SM, true);
    }
  }

  /// Flightcategory related
  /// base AGL of lowest significant cloud in feet
  late final int? lowestSignificantCloudBase = this.sky_condition?.lowestSignificantCloudBase??null;
  /// lowest visibility in miles
  late final double? lowestVisibility =  this.visibility?.minInMiles ??null;
  /// flight category, preset is calcutalion based on current values
  late FlightCategory flightCategory = FlightCategory.calc(this);

  ChangeIndicator get changeIndicator => ChangeIndicator.METAR;
}