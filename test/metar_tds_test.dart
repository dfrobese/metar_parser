
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/metar_raw_parser.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
  test('Metar test', () async {


    final lfbm =  MetarTafRawParser.parseMetarRawText("METAR LFBM 162130Z AUTO 06003KT CAVOK 07/06 Q1020 BECMG 0500 FG");
    lfbm.forEach((key, value) {
      print("$key $value");
    });

    expect(lfbm["typeMetar"], "METAR");
    expect(lfbm["station"], "LFBM");
    expect(lfbm["published"], "162130Z");
    expect(lfbm["mode"], "AUTO");
    expect(lfbm["wind"], "06003KT");
    expect(lfbm["clouds"], "CAVOK");
    expect(lfbm["temperature"], "07/06");
    expect(lfbm["altimeter"], "Q1020");
    expect(lfbm["changeMetar"], "BECMG 0500 FG");


    final lfbd =  MetarTafRawParser.parseMetarRawText("METAR LFBD 162130Z AUTO 24002KT 2500 0350 R23/0750D R05/0900D R29/1200U FG SHRA SCT001 BKN002 FEW002 07/07 Q1019 TEMPO 0500 FG VV///");
    lfbd.forEach((key, value) {
      print("$key $value");
    });
    expect(lfbd["typeMetar"], "METAR");
    expect(lfbd["station"], "LFBD");
    expect(lfbd["published"], "162130Z");
    expect(lfbd["mode"], "AUTO");
    expect(lfbd["wind"], "24002KT");
    expect(lfbd["visibility"], "2500 0350");
    expect(lfbd["rvr"], "R23/0750D R05/0900D R29/1200U");
    expect(lfbd["weather"], "FG SHRA");
    expect(lfbd["clouds"], "SCT001 BKN002 FEW002");
    expect(lfbd["temperature"], "07/07");
    expect(lfbd["altimeter"], "Q1019");
    expect(lfbd["changeMetar"], "TEMPO 0500 FG VV///");



    // EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG
    final eddv =  MetarTafRawParser.parseMetarRawText("METAR EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG");
    eddv.forEach((key, value) {
      print("$key $value");
    });
    expect(eddv["typeMetar"], "METAR");
    expect(eddv["station"], "EDDV");
    expect(eddv["published"], "151420Z");
    expect(eddv["mode"], "AUTO");
    expect(eddv["wind"], "26005KT");
    expect(eddv["visibility"], "9999");
    expect(eddv["clouds"], "OVC022");
    expect(eddv["temperature"], "09/06");
    expect(eddv["altimeter"], "Q1025");
    expect(eddv["changeMetar"], "NOSIG");



    ///
    //
    final Map<String, MetarTDS> metars = await MetarController().fullRequest();

    final map = metars['EDDV'] ;
    expect(map != null, true);
    expect(map!.station_id, 'EDDV');
    print(map.station_id);
    print(map.raw_text);
    print(map.visibility_statute_mi);
    // expect(map.wind.direction, map.moreWind.direction);
   // expect(map.wind.speed, map.moreWind.speed);
    expect((map.flightCategory != FlightCategory.NONE), true);
    print('${map.flightCategory}');

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
      final map =  MetarTafRawParser.parseMetarRawText(element.raw_text);
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