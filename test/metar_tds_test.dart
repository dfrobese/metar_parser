import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
  test('Metar test', () async {
    final Map<String, MetarTDS> metars = await MetarController().fullRequest();

    final eddv = metars['EDDV'] ;
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    print(eddv.raw_text);
    print(eddv.visibility_statute_mi);
    expect(eddv.wind.direction, eddv.moreWind.direction);
    expect(eddv.wind.speed, eddv.moreWind.speed);
    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,reason: "Station ${element.station_id}");
    });


    metars.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,reason: "Station ${element.station_id}");
    });

  });

}