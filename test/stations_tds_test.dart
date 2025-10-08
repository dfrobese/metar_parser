
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:latlong2/latlong.dart';

void main () {
  test('StationProvider fetchByID for EDDV', () async {
    final provider = StationProvider();
    await provider.fetchByID('EDDV');
    final dict = provider.stationDict;
    expect(dict.isNotEmpty, true);
    expect(dict.containsKey('EDDV'), true);
  });

  test('StationProvider fetchByLocation around EDDV', () async {
    // EDDV (Hannover): 52.4603, 9.6851
    final provider = StationProvider();
    final center = LatLng(52.4603, 9.6851);
    await provider.fetchByLocation(center: center);
    final dict = provider.stationDict;
    expect(dict.isNotEmpty, true);
    expect(dict.keys.any((k) => k == 'EDDV'), true);
  });

  test('StationProvider fetchByArea around EDDV', () async {
    final provider = StationProvider();
    final sw = LatLng(52.3, 9.5);
    final ne = LatLng(52.6, 9.9);
    await provider.fetchByArea(sw: sw, ne: ne);
    final dict = provider.stationDict;
    expect(dict.isNotEmpty, true);
    expect(dict.keys.any((k) => k == 'EDDV'), true);
  });

  test('StationProvider fullRequest', () async {
    final provider = StationProvider();
    await provider.fullRequest();
    final dict = provider.stationDict;
    expect(dict.isNotEmpty, true);
    expect(dict.keys.any((k) => k == 'EDDV'), true);
  });
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