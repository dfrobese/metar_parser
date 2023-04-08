import 'dart:developer' as developer;
import 'package:country/country.dart';
import 'package:metar_dart/metar_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:xml/xml.dart';


class TafTDS implements TDSElement {

  TafTDS._(this.raw_text, this.station_id, this.issue_time, this.latitude, this.longitude, this.elevation_m);

  factory TafTDS.fromElement(XmlElement metarElement) {
    var raw = metarElement.getElement('raw_text')?.text ?? "";
    var id = metarElement.getElement('station_id')?.text ?? "";
    var time = DateTime.parse(metarElement.getElement('issue_time')?.text ?? DateTime.now().toString());
    var latitude = double.parse(metarElement.getElement('latitude')?.text ?? "0");
    var longitude = double.parse(metarElement.getElement('longitude')?.text ?? "0");
    var elevation_m = double.parse(metarElement.getElement('elevation_m')?.text ?? "0");



    return TafTDS._(raw, id, time, latitude, longitude, elevation_m);
  }

  String raw_text; //KROS 101504Z AUTO 05009G14KT 7SM DZ OVC005 08/07 A2970 RMK AO2 LTG DSNT NW P0001
  String station_id;
  DateTime issue_time; //2022-11-10T15:04:00Z
  double latitude; // 45.7</latitude>d
  double longitude; // >-92.95</longitude>
  double elevation_m; //>282.0</elevation_m>
  //

   /// GPS coordinates of station
   late Coordinate coordinate =  Coordinate(latitude, longitude);
   late Taf taf = Taf(this.raw_text);


}