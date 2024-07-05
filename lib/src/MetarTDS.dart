
import 'package:metar_parser_dart/src/CloudStack.dart';
import 'package:metar_parser_dart/src/FlightCategory.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:country/country.dart';
import 'package:metar_dart/metar_dart.dart';
import 'package:xml/xml.dart';


class MetarTDS implements TDSElement, FlightCategoryRelated {


  MetarTDS._(this.raw_text, this.station_id, this.observation_time, this.latitude, this.longitude,
      this.temp_c, this.dewpoint_c, this.wind_dir_degrees, this.wind_speed_kt, this.wind_gust_kt,
      this.visibility_statute_mi, this.altim_in_hg, this.wx_string, this.sky_condition, this._flight_category,
      this.precip_in, this.elevation_m);

  factory MetarTDS.fromElement(XmlElement metarElement) {
    var raw = metarElement.getElement('raw_text')?.text ?? "";
    var id = metarElement.getElement('station_id')?.text ?? "";
    var time = DateTime.parse(metarElement.getElement('observation_time')?.text ?? DateTime.now().toString());
    var latitude = double.parse(metarElement.getElement('latitude')?.text ?? "0");
    var longitude = double.parse(metarElement.getElement('longitude')?.text ?? "0");
    var temp_c = double.parse(metarElement.getElement('temp_c')?.text ?? "0");
    var dewpoint_c = double.parse(metarElement.getElement('dewpoint_c')?.text ?? "0");

    var dir = metarElement.findElements('wind_dir_degrees');
    if (dir.length > 0) {
      // developer.log('wind found', name: 'my.app.category');
    }
    var dirString = metarElement.getElement('wind_dir_degrees')?.text ?? "0";
    var wind_dir_degrees = dirString == "VRB" ? 0.0 : double.parse(dirString);
    var wind_speed_kt = double.parse(metarElement.getElement('wind_speed_kt')?.text ?? "0");
    var wind_gust_kt = double.parse(metarElement.getElement('wind_gust_kt')?.text ?? "0");

    var visibility_statute_mi = null;
    var visibilityStr = metarElement.getElement('visibility_statute_mi')?.text;
    if (visibilityStr != null) {
      var match = RegExp(r'\d+').firstMatch(visibilityStr);
      if (match != null && match[0] != null) {
        visibility_statute_mi = double.parse(match[0]!);
      }
    }
   var altim_in_hg = double.parse(metarElement.getElement('altim_in_hg')?.text ?? "0");
    var flight_category = FlightCategory.parse(metarElement.getElement('flight_category')?.text ?? "NONE");
    var wx_string = metarElement.getElement('wx_string')?.text ?? "";
    var sky_condition = CloudStack.fromElement(metarElement);

    var precip_in = double.parse(metarElement.getElement('precip_in')?.text ?? "0");
    var elevation_m = double.parse(metarElement.getElement('elevation_m')?.text ?? "0");

    return MetarTDS._(raw, id, time, latitude, longitude, temp_c, dewpoint_c, wind_dir_degrees, wind_speed_kt, wind_gust_kt,
    visibility_statute_mi, altim_in_hg, wx_string, sky_condition, flight_category, precip_in, elevation_m);
  }

  String raw_text; //KROS 101504Z AUTO 05009G14KT 7SM DZ OVC005 08/07 A2970 RMK AO2 LTG DSNT NW P0001
  @override String station_id;
  DateTime observation_time; //2022-11-10T15:04:00Z
  double latitude; // 45.7</latitude>d
  @override double longitude; // >-92.95</longitude>
  double temp_c; // >8.0</temp_c>
  double dewpoint_c; // >7.0</dewpoint_c>
  double wind_dir_degrees; //>50</wind_dir_degrees>
  double wind_speed_kt; // >9</wind_speed_kt>
  double wind_gust_kt; // >14</wind_gust_kt>
  double ?visibility_statute_mi; // >7.0</visibility_statute_mi>
  double altim_in_hg; //>29.698818</altim_in_hg>
  // <quality_control_flags>
  // <auto>TRUE</auto>
  // <auto_station>TRUE</auto_station>
  // </quality_control_flags>
  String wx_string; // >DZ</wx_string>
  CloudStack sky_condition; // sky_cover="OVC" cloud_base_ft_agl="500"/>
  FlightCategory _flight_category; //>IFR</flight_category>
  double precip_in; // >0.01</precip_in>
  // <metar_type>METAR</metar_type>
  double elevation_m; //>282.0</elevation_m>
  //

   /// GPS coordinates of station
   late Coordinate coordinate =  Coordinate(latitude: latitude, longitude: longitude);
   /// horizontal visibility in status miles
   double? get visibility => this.visibility_statute_mi;
   /// base AGL of lowest significant cloud
   late double? lowestSignificantCloudBase = this.sky_condition.lowestSignificantCloudBase;
   /// Flight category VFR, MVFR, IFR or LIFR
   FlightCategory get flightCategory => this._flight_category == FlightCategory.NONE ? FlightCategory.calc(this) : this._flight_category;
   /// parsed metar information from raw string
   late Metar metar = Metar(this.raw_text);
   /// Wind
   late Wind wind = Wind(wind_speed_kt, wind_dir_degrees, wind_gust_kt);
   /// More Wind
   late Wind moreWind = Wind(metar.wind.speedInKnot ?? 0, metar.wind.directionInDegrees ?? 0, metar.wind.gustInKnot ?? 0, metar.windVariation.fromInDegrees, metar.windVariation.toInDegrees);


/// TODO  Visible runway length
}