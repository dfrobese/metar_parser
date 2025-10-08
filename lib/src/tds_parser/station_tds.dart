import 'package:country/country.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:xml/xml.dart';


class StationTDS extends TDSElement {

    @override String station_id;
    String wmo_id; //KROS 101504Z AUTO 05009G14KT 7SM DZ OVC005 08/07 A2970 RMK AO2 LTG DSNT NW P0001
    @override double latitude; // 45.7</latitude>d
    @override double longitude; // >-92.95</longitude>
    double elevation_m; //>282.0</elevation_m>
    String site;
    String state;
    String country;
    /// GPS coordinates of station
    late final Coordinate coordinate =  Coordinate(latitude: latitude, longitude: longitude);


    StationTDS._(this.station_id, this.wmo_id, this.latitude, this.longitude, this.elevation_m, this.site, this.state, this.country);

    /// Creates a new instance of [StationTDS] from the provided [XmlElement].
    ///
    /// Parses the given XML element and extracts the relevant data to
    /// initialize a [StationTDS] object.
    ///
    /// Throws an [Exception] if the XML element does not contain the
    /// required information for parsing.
    factory StationTDS.fromElement(XmlElement element) {
        var wmoId = element.getElement('wmo_id')?.innerText ?? "";
        var id = element.getElement('station_id')?.innerText ?? "";
        //var time = DateTime.parse(element.getElement('issue_time')?.text ?? DateTime.now().toString());
        var latitude = double.parse(element.getElement('latitude')?.innerText ?? "0") ;
        // latitude = (latitude >= -90.0 && latitude <= 90.0) ? latitude : 0;
        var longitude = double.parse(element.getElement('longitude')?.innerText ?? "0");
        // longitude = (longitude >= -180.0 && longitude <= 180.0) ? longitude : 0;
        var elevationM = double.parse(element.getElement('elevation_m')?.innerText ?? "0");
        var site = element.getElement('site')?.innerText ?? "";
        var state = element.getElement('state')?.innerText ?? "";
        var country = element.getElement('country')?.innerText ?? "";

        return StationTDS._(id, wmoId, latitude, longitude, elevationM, site, state, country);
    }

    
}