import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


/// A provider class for fetching TAF (Terminal Aerodrome Forecast) data.
///
/// This class allows configuration of the proxy host name for network requests.
/// Use [fetchTaf] to retrieve and parse TAF data as a map.
class TafProvider {
  /// The proxy host name to use for network requests.
  final String proxyHostName;

  /// Creates a [TafProvider] with an optional [proxyHostName].
  ///
  /// If [proxyHostName] is not provided, the default is an empty string (no proxy).
  TafProvider({this.proxyHostName = ''});

  /// Fetches and parses TAF data from the remote server.
  ///
  /// Returns a [Map] where the key is a [String] (station ID) and the value is a [TafTDS] object.
  /// Throws a [TDSFetchDataException] if the data cannot be retrieved or is invalid.
  Future<Map<String, TafTDS>> fetchTaf() async {
    developer.log('#Taf_Provider fullRequest');
    final Map<String, TafTDS> tdsDict = {};
    final TDSRequest request = TDSRequest(TDSRequestType.taf, proxyHostName);

    var content = await request.readZippedFile();
    final file = content.toString();
    if (file.length < 100) {
      developer.log('ERROR file not found');
      throw TDSFetchDataException("An error occured, file not found");
    }
    final map = request.parse(file);
    tdsDict.addAll(map.cast<String, TafTDS>());
    return tdsDict;
  }
}

/// A Riverpod provider for fetching TAF data with a configurable proxy host name.
final tafProvider = FutureProvider.family<Map<String, TafTDS>, String>((ref, proxyHostName) async {
  final provider = TafProvider(proxyHostName: proxyHostName);
  return await provider.fetchTaf();
});