import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';

import 'package:metar_parser_dart/src/TDSRequest.dart';

/// A provider class for fetching station data.
///
/// This class allows configuration of the proxy host name for network requests.
/// Use [fetchStation] to retrieve and parse station data as a map.
class StationProvider {
  /// The proxy host name to use for network requests.
  final String proxyHostName;

  /// Creates a [StationProvider] with an optional [proxyHostName].
  ///
  /// If [proxyHostName] is not provided, the default is an empty string (no proxy).
  StationProvider({this.proxyHostName = ''});

  /// Fetches and parses station data from the remote server.
  ///
  /// Returns a [Map] where the key is a [String] (station ID) and the value is a [StationTDS] object.
  /// Throws a [TDSFetchDataException] if the data cannot be retrieved or is invalid.
  Future<Map<String, StationTDS>> fetchStation() async {
    developer.log('#station_Provider fullRequest');
    final Map<String, StationTDS> tdsDict = {};
    final TDSRequest request = TDSRequest(TDSRequestType.station, proxyHostName);

    var content = await request.readZippedFile();
    final file = content.toString();
    if (file.length < 100) {
      developer.log('ERROR file not found');
      throw TDSFetchDataException("An error occured, file not found");
    }
    final map = request.parse(file);
    tdsDict.addAll(map.cast<String, StationTDS>());
    return tdsDict;
  }
}
