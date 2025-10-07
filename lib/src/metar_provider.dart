import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:flutter/foundation.dart';


class MetarProvider extends ChangeNotifier {
  final MetarController _controller;

  MetarProvider({String proxyHostName = ''})
      : _controller = MetarController(proxyHostName: proxyHostName);

  Map<String, MetarTDS> get metarDict => _controller.tdsDict;

  /// Fetches METAR data for a specified area.
  ///
  /// This asynchronous method retrieves meteorological data (METAR) for a given area.
  /// The area parameters and additional options should be provided as arguments.
  /// 
  /// Throws an exception if the fetch operation fails.
  ///
  /// Returns a [Future] that completes when the data has been fetched.
  Future<void> fetchByArea({
    required double lat0,
    required double lon0,
    required double lat1,
    required double lon1,
  }) async {
    await _controller.fetchByArea(
      lat0: lat0,
      lon0: lon0,
      lat1: lat1,
      lon1: lon1,
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
}





