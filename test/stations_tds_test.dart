import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
  test('Stations test', () async {
    final Map<String, StationTDS> stations = await StationController().fullRequest();
    final eddv = stations['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    stations.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false,reason: "Station ${element.station_id}");
    });
  });

}