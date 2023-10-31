import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
  test('Stations test', () async {
    TDSRequest request = TDSRequest.station;
    var file = await request.readZippedFile();
    final Map<String, StationTDS> stations = request.parse<StationTDS>(file);
    final eddv = stations['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    stations.values.toList().forEach((element) {
      expect((element.latitude > 90 || element.latitude < -90), false);
    });
  });

}