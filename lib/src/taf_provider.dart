import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// A provider class for fetching TAF (Terminal Aerodrome Forecast) data.
///
/// This class allows configuration of the proxy host name for network requests.
/// Use [fetchTaf] to retrieve and parse TAF data as a map.
class TafProvider  extends ChangeNotifier{
    final TafController _controller;

  /// Creates a [TafProvider] with an optional [proxyHostName].
  ///
  /// If [proxyHostName] is not provided, the default is an empty string (no proxy).
  TafProvider({String proxyHostName = ''})
   : _controller = TafController(proxyHostName: proxyHostName);

  /// Returns a map containing TAF (Terminal Aerodrome Forecast) data, where each key is a string identifier
  /// and each value is a [TafTDS] object representing the forecast details.
  ///
  /// The map is retrieved from the internal controller's `tdsDict` property.
  Map<String, TafTDS> get _tafDict => _controller.tdsDict;

  /// Returns the number of cached TAF entries.
  int get length => _tafDict.length;

  /// Fetches TAF data for a specified area.
  ///
  /// This asynchronous method retrieves forecast data for a given area.
  /// Throws an exception if the fetch operation fails.
  ///
  /// Returns a [Future] that completes when the data has been fetched.
  Future<void> fetchByArea({
    required LatLng sw,
    required LatLng ne,
  }) async {
    await _controller.fetchByArea(
      sw: sw,
      ne: ne,
    );
    notifyListeners();
  }

  /// Performs a complete request to retrieve and process TAF data.
  ///
  /// This asynchronous method initiates a full data fetch operation,
  /// handling all necessary steps to obtain and parse TAF information.
  /// It may throw exceptions if the request fails or if data processing encounters errors.
  ///
  /// Returns a [Future] that completes when the request and processing are finished.
  Future<void> fullRequest() async {
    await _controller.fullRequest();
    notifyListeners();
  }

  
  /// Fetches TAF data for a specific ICAO station ID and updates state.
  Future<void> fetchByID(String stationId) async {
    await _controller.fetchByID(stationId);
    notifyListeners();
  }

  /// Fetches TAF data for a specific location (center point) and updates state.
  Future<void> fetchByLocation({
    required LatLng center
  }) async {
    await _controller.fetchByLocation(center: center);
    notifyListeners();
  }

  /// Retrieves a TAF entry by its station identifier, or null if unavailable.
  TafTDS? getById(String stationId) => _tafDict[stationId];

  /// Sorts forecasts by their distance to the provided position.
  List<TafTDS> sortByLocation(LatLng position) {
    return _controller.sortStationsBy(position);
  }

  /// Sorts forecasts by distance to another station identified by [stationId].
  List<TafTDS> sortByStation(String stationId) {
    final position = _tafDict[stationId]?.position;
    if (position == null) return [];
    return _controller.sortStationsBy(position);
  }
}

