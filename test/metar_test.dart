import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('Static Metar raw parser test', () {
    final lfbm = MetarRaw.parse(
        "METAR LFBM 162130Z AUTO 06003KT CAVOK 07/06 Q1020 BECMG 0500 FG");
    lfbm.data.forEach((key, value) {
      print("$key $value");
    });
    expect(lfbm.data["typeMetar"], "METAR");
    expect(lfbm.data["station"], "LFBM");
    expect(lfbm.data["published"], "162130Z");
    expect(lfbm.data["mode"], "AUTO");
    expect(lfbm.data["windGusts"], "06003KT");
    expect(lfbm.data["clouds"], "CAVOK");
    expect(lfbm.data["temperature"], "07/06");
    expect(lfbm.data["altimeter"], "Q1020");
    expect(lfbm.data["changeMetar"], "BECMG 0500 FG");
    // expect wind
    expect(lfbm.wind?.direction == 60, true);
    // check cloudbase
    expect(lfbm.lowestSignificantCloudBase == 5000, true);
    // check visibility
    expect(lfbm.lowestVisibility == 6, true);
    // check flight category
    expect(lfbm.flightCategory == FlightCategory.VFR, true);

    final lfbd = MetarRaw.parse(
        "METAR LFBD 162130Z AUTO 24002KT 2500 0350 R23/0750D R05/0900D R29/1200U FG SHRA SCT001 BKN002 FEW002 07/07 Q1019 TEMPO 0500 FG VV///");
    lfbd.data.forEach((key, value) {
      print("$key $value");
    });
    expect(lfbd.data["typeMetar"], "METAR");
    expect(lfbd.data["station"], "LFBD");
    expect(lfbd.data["published"], "162130Z");
    expect(lfbd.data["mode"], "AUTO");
    expect(lfbd.data["windGusts"], "24002KT");
    expect(lfbd.data["visibility"], "2500 0350");
    expect(lfbd.data["rvr"], "R23/0750D R05/0900D R29/1200U");
    expect(lfbd.data["weatherMetar"], "FG SHRA");
    expect(lfbd.data["clouds"], "SCT001 BKN002 FEW002");
    expect(lfbd.data["temperature"], "07/07");
    expect(lfbd.data["altimeter"], "Q1019");
    expect(lfbd.data["changeMetar"], "TEMPO 0500 FG VV///");
    //
    expect(lfbd.station_id == "LFBD", true);
    // expect wind
    expect(lfbd.wind?.direction == 240, true);
    // check cloudbase
    expect(lfbd.lowestSignificantCloudBase == 200, true);
    // check visibility
    expect(lfbd.visibility!.minVisibility == 2500, true);
    // check flight category
    expect(lfbd.flightCategory == FlightCategory.LIFR, true);
    // check rvr
    expect(lfbd.rvr?.first?.runway == "23", true);

    // EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG
    final eddv = MetarRaw.parse(
        "METAR EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG");
    eddv.data.forEach((key, value) {
      print("$key $value");
    });
    expect(eddv.data["typeMetar"], "METAR");
    expect(eddv.data["station"], "EDDV");
    expect(eddv.data["published"], "151420Z");
    expect(eddv.data["mode"], "AUTO");
    expect(eddv.data["windGusts"], "26005KT");
    expect(eddv.data["visibility"], "9999");
    expect(eddv.data["clouds"], "OVC022");
    expect(eddv.data["temperature"], "09/06");
    expect(eddv.data["altimeter"], "Q1025");
    expect(eddv.data["changeMetar"], "NOSIG");
    // expect wind
    expect(eddv.wind?.direction == 260, true);
    // check cloudbase
    expect(eddv.lowestSignificantCloudBase == 2200, true);
    // check visibility
    expect(eddv.visibility!.minVisibility == 9999, true);
    // check flight category
    expect(eddv.flightCategory == FlightCategory.MVFR, true);

  });

  test('Full Metar test', () async {
    ///
    final Map<String, MetarTDS> metars = await MetarController().fullRequest();

    final map = metars['EDDV'];
    expect(map != null, true);
    expect(map!.station_id, 'EDDV');
    final eddv = MetarRaw.parse(map.raw_text);

    // expect(map.windGusts.direction, map.morewindGusts.direction);
    // expect(map.windGusts.speed, map.morewindGusts.speed);
    expect((map.flightCategory == eddv.flightCategory), true);

    // Test all coordinates
    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,
          reason: "Station ${element.station_id}");
    });
    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,
          reason: "Station ${element.station_id}");
    });

    var failureCount = 0;
    // parse all metar raw strings
    metars.values.toList().forEach((element) {
      expect(element.raw_text.length > 0, true);
      print("Parsed data ${element.raw_text}");
      final raw = MetarRaw.parse(element.raw_text);
      expect(raw.data.length > 0, true);

      if (element.flightCategory != FlightCategory.NONE) {
        try {
          expect(raw.flightCategory, element.flightCategory);
        } catch (e) {
          failureCount++;
          print("Raw not fitted for ${element.station_id}");
        }
      }
    });
    print("Flight category failed $failureCount");
  });
}
