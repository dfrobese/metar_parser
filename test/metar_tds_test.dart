
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/metar_raw_parser.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
  test('Metar test', () async {

    // EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG
    final map =  MetarRawParser.parseMetarRawText("METAR EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG");
    map.forEach((key, value) {
      print("$key $value");
    });
    //
    final Map<String, MetarTDS> metars = await MetarController().fullRequest();

    final eddv = metars['EDDV'] ;
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    print(eddv.raw_text);
    print(eddv.visibility_statute_mi);
    expect(eddv.wind.direction, eddv.moreWind.direction);
    expect(eddv.wind.speed, eddv.moreWind.speed);
    expect((eddv.flightCategory != FlightCategory.NONE), true);
    print('${eddv.flightCategory}');

    // Test all coordinates
    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,reason: "Station ${element.station_id}");
    });
    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,reason: "Station ${element.station_id}");
    });


    // parse all metar raw strings
    metars.values.toList().forEach((element) {
    expect(element.raw_text.length > 0, true);
      print("Parsed data ${element.raw_text}");
      final map =  MetarRawParser.parseMetarRawText(element.raw_text);
      expect(map.length > 0, true);
      if (map.length < 1)  {
        print("Failed ${element.raw_text}");
      }
      map.forEach((key, value) {
         print("$key $value");
       });
    });
  });

}