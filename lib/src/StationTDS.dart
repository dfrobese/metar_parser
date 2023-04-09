import 'package:country/country.dart';
import 'package:metar_dart/metar_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:xml/xml.dart';


class StationTDS implements TDSElement {
    StationTDS._(this.station_id, this.wmo_id, this.latitude, this.longitude, this.elevation_m, this.site, this.state, this.country);

    factory StationTDS.fromElement(XmlElement element) {
        var wmoId = element.getElement('wmo_id')?.text ?? "";
        var id = element.getElement('station_id')?.text ?? "";
        var time = DateTime.parse(element.getElement('issue_time')?.text ?? DateTime.now().toString());
        var latitude = double.parse(element.getElement('latitude')?.text ?? "0");
        var longitude = double.parse(element.getElement('longitude')?.text ?? "0");
        var elevationM = double.parse(element.getElement('elevation_m')?.text ?? "0");
        var site = element.getElement('site')?.text ?? "";
        var state = element.getElement('state')?.text ?? "";
        var country = element.getElement('country')?.text ?? "";

        return StationTDS._(id, wmoId, latitude, longitude, elevationM, site, state, country);
    }

    String station_id;
    String wmo_id; //KROS 101504Z AUTO 05009G14KT 7SM DZ OVC005 08/07 A2970 RMK AO2 LTG DSNT NW P0001
    double latitude; // 45.7</latitude>d
    double longitude; // >-92.95</longitude>
    double elevation_m; //>282.0</elevation_m>
    String site;
    String state;
    String country;
    /// GPS coordinates of station
    late Coordinate coordinate =  Coordinate(latitude, longitude);

}