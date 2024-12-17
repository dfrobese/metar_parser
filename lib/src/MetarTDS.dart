
import 'dart:developer' as developer;
import 'package:metar_parser_dart/src/CloudStack.dart';
import 'package:metar_parser_dart/src/FlightCategory.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:country/country.dart';
import 'package:xml/xml.dart';
import 'CloudCoverage.dart';
import 'PresentWeather.dart';
import 'raw_parser/metar_raw_parser.dart';


class MetarTDS implements TDSElement, FlightCategoryRelated {

  String raw_text; //KROS 101504Z AUTO 05009G14KT 7SM DZ OVC005 08/07 A2970 RMK AO2 LTG DSNT NW P0001
  @override String station_id;
  DateTime observation_time; //2022-11-10T15:04:00Z
  @override double latitude; // 45.7</latitude>d
  @override double longitude; // >-92.95</longitude>
  XmlElement metarElement;

  MetarTDS._(this.raw_text, this.station_id, this.observation_time, this.latitude, this.longitude, this.metarElement);

  factory MetarTDS.fromElement(XmlElement metarElement) {
    var raw = metarElement.getElement('raw_text')?.innerText ?? "";
    var id = metarElement.getElement('station_id')?.innerText ?? "";
    var time = DateTime.parse(metarElement.getElement('observation_time')?.innerText ?? DateTime.now().toString());
    var latitude = double.parse(metarElement.getElement('latitude')?.innerText ?? "0");
    var longitude = double.parse(metarElement.getElement('longitude')?.innerText ?? "0");
    return MetarTDS._(raw, id, time, latitude, longitude, metarElement);
  }



  /// GPS coordinates of station
  late Coordinate coordinate = Coordinate(latitude: latitude, longitude: longitude);
  /// elevation of station
  late double elevation_m = double.parse(metarElement.getElement('elevation_m')?.innerText ?? "0");
  /// parsed raw text information
  late Map<String, String?> parsedRawText = MetarTafRawParser.parseMetarRawText(raw_text);
  /// get wind parameters
  late Wind wind = Wind.fromElement(metarElement);
  /// ambient pressure
  late double altim_in_hg = double.parse(metarElement.getElement('altim_in_hg')?.innerText ?? "0");
  /// internal flight category from data
  late FlightCategory _flight_category = FlightCategory.parse(metarElement.getElement('flight_category')?.innerText ?? "NONE");
  /// Flight category VFR, MVFR, IFR or LIFR
  FlightCategory get flightCategory => this._flight_category == FlightCategory.NONE ? FlightCategory.calc(this) : this._flight_category;
  /// weather text
  late String? wx_string = metarElement.getElement('wx_string')?.innerText;
  /// Decoded weather or null if not reported
  late PresentWeather? weather = wx_string != null ? PresentWeather.parse(wx_string!) : null;
  /// cloud information
  late CloudStack sky_condition = CloudStack.fromElement(metarElement);
  /// base AGL of lowest significant cloud
  late double? lowestSignificantCloudBase = this.sky_condition.lowestSignificantCloudBase;
  /// precipation
  late double precip_in = double.parse(metarElement.getElement('precip_in')?.innerText ?? "0");
  /// temperatures
  late double temp_c = double.parse(metarElement.getElement('temp_c')?.innerText ?? "0");
  late double dewpoint_c = double.parse(metarElement.getElement('dewpoint_c')?.innerText ?? "0");
  /// internal visibility string
  late String? _visibilityStr = metarElement.getElement('visibility_statute_mi')?.innerText;
  /// visibility status miles
  late double? visibility_statute_mi = (() {
    if (_visibilityStr != null) {
      var match = RegExp(r'\d+').firstMatch(_visibilityStr!);
      if (match != null && match[0] != null) {
        return double.parse(match[0]!);
      }
    }
    return null;
  })();
  /// horizontal visibility in always in status miles
  double? get visibility => this.visibility_statute_mi;
}

