import 'dart:developer' as developer;
import 'package:http/http.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/tds_parser/station_tds.dart';
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import './extension/decompress_native.dart'
    if (dart.library.html) './extension/decompress_web.dart';

abstract class TDSElement {
  String get station_id;
  double get latitude; // 45.7</latitude>d
  double get longitude; // >-92.95</longitude>
}

enum TDSRequestType {
  metar,
  taf,
  station;

//  final String dataServerPath = "https://aviationweather.gov/data/cache/stations.cache.xml";
//  final String dataServerPath = "https://aviationweather-bldr.ncep.noaa.gov/adds/dataserver_current/current/";

  /// Retrieves the token associated with the current request instance.
  ///
  /// This token is typically used for metar or tafs
  /// purposes in requests. Ensure that the token is securely managed
  /// and not exposed in logs or error messages.
  String get token {
    switch (this) {
      case TDSRequestType.metar:
      case TDSRequestType.taf:
        return this.name.toUpperCase();
      case TDSRequestType.station:
        return "Station";
    }
  }

  /// Gets the type of the current request instance.
  ///
  /// This property returns the specific type associated with the instance,
  /// which can be used to identify or differentiate between various requests
  /// within the context of the required data.
  Type get type {
    switch (this) {
      case TDSRequestType.metar:
        return MetarTDS;
      case TDSRequestType.taf:
        return TafTDS;
      case TDSRequestType.station:
        return StationTDS;
    }
  }

  fromElement<TDSElement>(XmlElement element) {
    switch (this) {
      case TDSRequestType.metar:
        return MetarTDS.fromElement(element);
      case TDSRequestType.taf:
        return TafTDS.fromXml(element);
      case TDSRequestType.station:
        return StationTDS.fromElement(element);
    }
  }

  /// Gets the cached File for the requested data instance.
  ///
  /// This property retrieves a string representing the cached file
  /// associated with the waether object. The exact behavior and format of
  /// the cached path depend on the implementation details.
  String get _cachedFileName {
    switch (this) {
      case TDSRequestType.metar:
        return "metars.cache.xml";
      case TDSRequestType.taf:
        return "tafs.cache.xml";
      case TDSRequestType.station:
        return 'stations.cache.xml';
    }
  }

  String get _endpoint {
    switch (this) {
      case TDSRequestType.metar:
        return "metars";
      case TDSRequestType.taf:
        return "tafs";
      case TDSRequestType.station:
        return 'stationinfo';
    }
  }

  /// Returns a [Uri] for cached files based on whether the files are zipped and the specified proxy host name.
  ///
  /// [isZipped] determines if the cached files are in a zipped format.
  /// [proxyHostName] is the host name of the proxy server to use for the URI.
  ///
  /// Returns a [Uri] pointing to the location of the cached files.
  Uri cachedFilesUri(bool isZipped, String proxyHostName) {
    final fileName = isZipped ? '$_cachedFileName.gz' : _cachedFileName;
    final isProxY = kIsWeb && proxyHostName.isNotEmpty;
    final host = isProxY ? proxyHostName : 'aviationweather.gov';
    final path = '${isProxY ? '/aviationweather' : ''}/data/cache/$fileName';
    return Uri(scheme: 'https', host: host, path: path);
  }

  /// Constructs a [Uri] for a request filtered by a specific area.
  ///
  /// The [byArea] method allows you to generate a URI that targets a particular
  /// geographical area for the request. Provide the necessary parameters to
  /// specify the area of interest.
  ///
  /// Returns a [Uri] representing the endpoint for the area-based request.
  Uri byArea({
    required double lat0,
    required double lon0,
    required double lat1,
    required double lon1,
    String? proxyHostName
  }) {
    final isProxy = kIsWeb && proxyHostName != null && proxyHostName.isNotEmpty;
    final host = isProxy ? proxyHostName : 'aviationweather.gov';
    final path = isProxy ? '/aviationweather/api/data/$_endpoint' : '/api/data/$_endpoint';
    return Uri(
      scheme: 'https',
      host: host,
      path: path,
      queryParameters: {
        'bbox': '$lat0,$lon0,$lat1,$lon1',
        'format': 'xml',
      },
    );
  }
}

/// A class representing a TDS (Terminal Data Service) request.
///
/// This class is used to encapsulate the details and functionality
/// required to create and manage requests to the TDS system.
class TDSRequest {
  final TDSRequestType type;
  final String proxyHostName;

  TDSRequest(this.type, [this.proxyHostName = '']);

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile() async {
    Uri link = type.cachedFilesUri(false, proxyHostName);
    try {
      Response response = await get(link);
      if (response.statusCode != 200) throw Exception('${response.statusCode}');
      return response.body;
    } on Exception {
      developer.log("Error: No Internet connection on $link");
      return "";
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String?> readZippedFile() async {
    Uri link = type.cachedFilesUri(true, proxyHostName);
    try {
      var bytes;
      // read bytes
      Response response = await get(link);
      if (response.statusCode != 200)
        throw TDSFetchDataException('${response.statusCode}');
      bytes = response.bodyBytes;
      // unzip bytes
      String result = decompressZlib(bytes);

      return result;
    } on Exception {
      developer.log("Error: No Internet connection on $link");
      return null;
    }
  }

  /// Parses the given response body and converts it into a map of `TDSElement` objects.
  ///
  /// The keys in the returned map are strings representing specific identifiers,
  /// and the values are `TDSElement` objects containing the parsed data.
  ///
  /// - Parameter body: The response body as a string to be parsed.
  /// - Returns: A map where the keys are strings and the values are `TDSElement` objects.
  Map<String, TDSElement> parse(String body) {
    if (body.length < 1) {
      developer.log("Error: no zipped metar fetched");
      throw TDSFetchDataException("No http connection to NOAA TDS");
    }
    var document = XmlDocument.parse(body);
    var root = document.getElement('data');
    assert(root == null);
    // map all stations
    final elements = document.findAllElements(type.token);
    var map = Map<String, TDSElement>.fromIterable(elements,
        key: (item) => item.getElement('station_id')?.text!,
        value: (item) => type.fromElement<TDSElement>(item));

    filterFalseEntries(map);
    return map;
  }

  /// Filters out entries in the provided map where the condition evaluates to false.
  ///
  /// This method takes a map of string keys and `TDSElement` values, and removes
  /// entries that do not meet a specific condition. The exact filtering logic
  /// should be implemented within the method.
  ///
  /// - Parameter elements: A map of string keys to `TDSElement` values to be filtered.
  /// - Returns: The filtered map with only the entries that meet the condition.
  filterFalseEntries(Map<String, TDSElement> elements) {
    elements.removeWhere((key, value) {
      return (value.latitude < -90 || value.latitude > 90);
    });
  }

  /// Fetch data for a specific map area (bounding box) and return a map of TDSElements.
  /// The endpoint and XML element are determined by the TDSRequestType.
  /// [lat0, lon0] is the southwest corner, [lat1, lon1] is the northeast corner.
  /// Returns a map where the keys are station IDs and the values are TDSElement objects.
  Future<Map<String, TDSElement>?> fetchByArea({
    required double lat0,
    required double lon0,
    required double lat1,
    required double lon1,
  }) async {
    // Determine endpoint path based on TDSRequestType
    final uri = type.byArea(
        lat0: lat0,
        lon0: lon0,
        lat1: lat1,
        lon1: lon1,
        proxyHostName: proxyHostName);
    try {
      final response = await get(uri);
      if (response.statusCode == 200) {
        return parse(response.body);
      } else {
        developer.log('Failed to fetch $type: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      developer.log('Error fetching $type by bounding box: $e');
      return null;
    }
  }
}
