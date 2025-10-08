
import 'package:latlong2/latlong.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/test.dart';

Future<StationProvider> _providerWithStation(String stationId) async {
  final provider = StationProvider();
  await provider.fetchByID(stationId);
  return provider;
}

void main() {
  const hannover = 'EDDV';
  const hannoverLat = 52.4603;
  const hannoverLon = 9.6851;

  test('fetchByID populates provider with requested station', () async {
    final provider = await _providerWithStation(hannover);
    expect(provider.length, greaterThan(0));
    expect(provider.getById(hannover)?.station_id, hannover);
  });

  test('fetchByLocation hits expected station proximity', () async {
    final provider = StationProvider();
    await provider.fetchByLocation(center: const LatLng(hannoverLat, hannoverLon));
    expect(provider.length, greaterThan(0));
    expect(provider.getById(hannover)?.station_id, isNotNull);
  });

  test('fetchByArea returns stations within the bounding box', () async {
    final provider = StationProvider();
    await provider.fetchByArea(
      sw: const LatLng(52.3, 9.5),
      ne: const LatLng(52.6, 9.9),
    );
    expect(provider.length, greaterThan(0));
    expect(provider.getById(hannover)?.station_id, isNotNull);
  });

  test('fullRequest pulls the complete station list', () async {
    final provider = StationProvider();
    await provider.fullRequest();
    expect(provider.length, greaterThan(0));
    expect(provider.getById(hannover)?.station_id, hannover);
  });

  test('StationController fullRequest returns valid coordinates', () async {
    final stations = await StationController().fullRequest();
    final eddv = stations[hannover];
    expect(eddv, isNotNull);
    expect(eddv!.station_id, hannover);
    for (final element in stations.values) {
      expect(
        element.latitude >= -90 && element.latitude <= 90,
        isTrue,
        reason: 'Station ${element.station_id} has invalid latitude',
      );
    }
  });
}
