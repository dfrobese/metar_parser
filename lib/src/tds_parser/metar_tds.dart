
import 'package:latlong2/latlong.dart';
import 'package:metar_parser_dart/src/cloud_stack.dart';
import 'package:metar_parser_dart/src/flight_category.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/tds_parser/forecast_tds.dart';
import 'package:metar_parser_dart/src/wind.dart';
import 'package:country/country.dart';
import 'package:xml/xml.dart';
import '../cloud_coverage.dart';
import '../present_weather.dart';


class MetarTDS extends TDSElement with FlightCategoryRelated {

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
  late final Coordinate coordinate = Coordinate(latitude: latitude, longitude: longitude);
  /// elevation of station
  late final double elevation_m = double.parse(metarElement.getElement('elevation_m')?.innerText ?? "0");
  /// get wind parameters
  late final Wind wind = Wind.fromElement(metarElement);
  /// ambient pressure
  late final double altim_in_hg = double.parse(metarElement.getElement('altim_in_hg')?.innerText ?? "0");
  /// internal flight category from data
  late final FlightCategory _flight_category = FlightCategory.parse(metarElement.getElement('flight_category')?.innerText ?? "NONE");
    /// weather text
  late final String? wx_string = metarElement.getElement('wx_string')?.innerText;
  /// Decoded weather or null if not reported
  late final PresentWeather? weather = wx_string != null ? PresentWeather.parse(wx_string!) : null;
  /// cloud information
  late final CloudStack? sky_condition = CloudStack.fromElement(metarElement);
  /// precipation
  late final double precip_in = double.parse(metarElement.getElement('precip_in')?.innerText ?? "0");
  /// temperatures
  late final double temp_c = double.parse(metarElement.getElement('temp_c')?.innerText ?? "0");
  late final double dewpoint_c = double.parse(metarElement.getElement('dewpoint_c')?.innerText ?? "0");
  /// internal visibility string
  late final String? _visibilityStr = metarElement.getElement('visibility_statute_mi')?.innerText;
  /// visibility status miles
  late final double? visibility_statute_mi = (() {
    if (_visibilityStr != null) {
      var match = RegExp(r'\d+').firstMatch(_visibilityStr!);
      if (match != null && match[0] != null) {
        return double.parse(match[0]!);
      }
    }
    // check if CAVOK
    if (this.sky_condition?.first.coverage == CloudCoverage.CAVOK) {
      return 6.0;
    }
    return null;
  })();

  /// FlightCategoryRelated
  /// base AGL of lowest significant cloud
  late final int? lowestSignificantCloudBase = this.sky_condition?.lowestSignificantCloudBase??null;
  /// horizontal visibility in always in status miles
  double? get lowestVisibility => this.visibility_statute_mi;
  /// Flight category VFR, MVFR, IFR or LIFR
  late FlightCategory flightCategory = this._flight_category == FlightCategory.NONE ? FlightCategory.calc(this) : this._flight_category;
  /// get type of change
  ChangeIndicator get changeIndicator => ChangeIndicator.METAR;


}

