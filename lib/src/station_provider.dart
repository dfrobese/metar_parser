
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';

class StationProvider extends ChangeNotifier {
  final StationController _controller;

  StationProvider({String proxyHostName = ''})
      : _controller = StationController(proxyHostName: proxyHostName);

  Map<String, StationTDS> get stationDict => _controller.tdsDict;

  /// Fetches all stations (full request) and updates state.
  Future<void> fullRequest() async {
    await _controller.fullRequest();
    notifyListeners();
  }

  /// Fetches station data for a specific ICAO station ID and updates state.
  Future<void> fetchByID(String stationId) async {
    await _controller.fetchByID(stationId);
    notifyListeners();
  }

  /// Fetches station data for a specific location (center point) and updates state.
  Future<void> fetchByLocation({
    required LatLng center
  }) async {
    await _controller.fetchByLocation(center: center);
    notifyListeners();
  }

  /// Fetches station data for a specified area (bounding box) and updates state.
  Future<void> fetchByArea({
    required LatLng sw,
    required LatLng ne,
  }) async {
    await _controller.fetchByArea(sw: sw, ne: ne);
    notifyListeners();
  }
}
