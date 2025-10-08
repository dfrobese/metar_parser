import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MetarProvider extends ChangeNotifier {

  final MetarController _controller;

  MetarProvider({String proxyHostName = ''})
      : _controller = MetarController(proxyHostName: proxyHostName);

  Map<String, MetarTDS> get _metarDict => _controller.tdsDict;

  /// Fetches METAR data for a specified area.
  ///
  /// This asynchronous method retrieves meteorological data (METAR) for a given area.
  /// The area parameters and additional options should be provided as arguments.
  /// 
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

  /// Performs a complete request to retrieve and process METAR data.
  ///
  /// This asynchronous method initiates a full data fetch operation,
  /// handling all necessary steps to obtain and parse METAR information.
  /// It may throw exceptions if the request fails or if data processing encounters errors.
  ///
  /// Returns a [Future] that completes when the request and processing are finished.
  Future<void> fullRequest() async {
    await _controller.fullRequest();
    notifyListeners();
  }

  
  /// Fetches METAR data for a specific ICAO station ID and updates state.
  Future<void> fetchByID(String stationId) async {
    await _controller.fetchByID(stationId);
    notifyListeners();
  }

  /// Fetches METAR data for a specific location (center point) and updates state.
  Future<void> fetchByLocation({
    required LatLng center
  }) async {
    await _controller.fetchByLocation(center: center);
    notifyListeners();
  }

  /// Sorts the list of [MetarTDS] stations by their distance to the given [position].
  ///
  /// [position]: The reference [LatLng] location to sort stations by proximity.
  List<MetarTDS> sortStationsByPosition(LatLng position) {
    return _controller.sortStationsBy(position);
  }

  /// Sorts the list of [MetarTDS] stations by their distance to the given [position].
  ///
  /// [position]: The reference [LatLng] location to sort stations by proximity.
  List<MetarTDS> sortStationsById(String stationId) {
    final pos = _controller.tdsDict[stationId]?.position;
    if (pos == null) return [];
    return _controller.sortStationsBy(pos);
  }

  /// Returns the number of entries in the `_metarDict`.
  ///
  /// This getter provides the current length of the METAR dictionary,
  /// indicating how many METAR records are available.
  int get length => _metarDict.length;

  /// Retrieves a [MetarTDS] instance corresponding to the provided [stationId].
  ///
  /// Throws an exception if no matching station is found.
  ///
  /// [stationId]: The identifier of the station to retrieve.
  /// Returns the [MetarTDS] associated with the given [stationId].
  MetarTDS? getById(String stationId) {
    return _metarDict[stationId];
  }


}