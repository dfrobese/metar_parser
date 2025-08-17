import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';



/// Provides functionality to fetch and parse METAR (Meteorological Aerodrome Report) data.
/// 
/// This class is responsible for retrieving METAR information from various sources
/// and parsing it into a usable format for the application.
class MetarProvider {
  final String proxyHostName;

  /// Creates a [MetarProvider] instance with an optional proxy host name.
  /// 
  /// The [proxyHostName] parameter allows specifying a proxy server's host name
  /// to be used for network requests. If not provided, it defaults to an empty string,
  /// indicating that no proxy will be used.
  MetarProvider({this.proxyHostName = ''});

  /// Fetches METAR (Meteorological Aerodrome Report) data asynchronously.
  ///
  /// Returns a [Future] that completes with a [Map] where the keys are
  /// [String] identifiers (such as airport codes) and the values are [MetarTDS]
  /// objects containing the corresponding METAR data.
  ///
  /// Throws an exception if the data retrieval fails.
  Future<Map<String, MetarTDS>> fetchMetar() async {
    final Map<String, MetarTDS> tdsDict = {};
    final TDSRequest request = TDSRequest(TDSRequestType.metar, proxyHostName);

    var content = await request.readZippedFile();
    var file;
    if (content != null && (file = content.toString()).length < 100) {
      developer.log('ERROR file not found');
      throw TDSFetchDataException("An error occured, file not found");
    }
    final map = request.parse(file);
    tdsDict.addAll(map.cast<String, MetarTDS>());
    return tdsDict;
  }
}


