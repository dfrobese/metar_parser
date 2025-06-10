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
        return  "metars.cache.xml";
      case TDSRequestType.taf:
        return  "tafs.cache.xml";
      case TDSRequestType.station:
        return 'stations.cache.xml';
    }
  }

  /// Returns the [Uri] for cached files, optionally specifying if the files are zipped.
  ///
  /// [isZipped] determines whether the URI should point to zipped files (`true`)
  /// or to unzipped files (`false`).
  ///
  /// Returns a [Uri] representing the location of the cached files.
  Uri cachedFilesUri(bool isZipped) {
    final fileName = isZipped ? '$_cachedFileName.gz' : _cachedFileName;
     if (kIsWeb) {
        // Runs on web: Proxy API call
        return Uri(host:"/aviationweather", // see proxy config
        path: '$fileName');
    }
    else {
      // Runs on mobile or desktop: Direct API call

      return Uri(
        scheme: 'https',
        host: 'aviationweather.gov',
        path: '/data/cache/$fileName',
        );
    }
  }
}

/// A class representing a TDS (Terminal Data Service) request.
/// 
/// This class is used to encapsulate the details and functionality
/// required to create and manage requests to the TDS system.
class TDSRequest {
  final TDSRequestType type;

  TDSRequest(this.type);

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile() async {
    Uri link = type.cachedFilesUri(false);
    try {
      Response response = await get(link);
      if (response.statusCode != 200)
        throw Exception('${response.statusCode}');
      return response.body;
    } on Exception {
      developer.log("Error: No Internet connection on $link");
      return "";
    }
  }


  /// read file based Metar/Taf/Station information with all entries
  Future<String?> readZippedFile() async {
    Uri link = type.cachedFilesUri(true);
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
}
