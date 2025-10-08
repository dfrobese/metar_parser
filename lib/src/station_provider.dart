
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';

class StationProvider extends ChangeNotifier {
  final StationController _controller;

  StationProvider({String proxyHostName = ''})
      : _controller = StationController(proxyHostName: proxyHostName);

  Map<String, StationTDS> get _stationDict => _controller.tdsDict;

  /// Returns the number of known stations.
  int get length => _stationDict.length;

  /// Fetches all stations (full request) and updates state.
  Future<void> fullRequest() async {
    await _controller.fullRequest();
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

  /// Fetches station data for a specific ICAO station ID and updates state.
  Future<void> fetchByID(String stationId) async {
    await _controller.fetchByID(stationId);
    notifyListeners();
  }

  /// Retrieves a station by its identifier, or null if not fetched yet.
  StationTDS? getById(String stationId) => _stationDict[stationId];

  /// Sorts stations by their distance to the provided position.
  List<StationTDS> sortByPosition(LatLng position) {
    return _controller.sortStationsBy(position);
  }

  /// Sorts stations by their distance to another station, identified by [stationId].
  List<StationTDS> sortByStation(String stationId) {
    final position = _stationDict[stationId]?.position;
    if (position == null) return [];
    return _controller.sortStationsBy(position);
  }


}
