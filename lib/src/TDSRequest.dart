
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

//  final String dataServerPath = "https://aviationweather.gov/adds/dataserver_current/";
//  final String dataServerPath = "https://aviationweather-bldr.ncep.noaa.gov/adds/dataserver_current/current/";
  String get dataServerPath {
    if (kIsWeb) {
      return "https://corsproxy.io/?url=https://aviationweather.gov/data/cache/";
    }
    return "https://aviationweather.gov/data/cache/";
  }

  String get token {
    switch (this) {
      case TDSRequestType.metar:
      case TDSRequestType.taf:
        return this.name.toUpperCase();
      case TDSRequestType.station:
        return "Station";
    }
  }

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

  String get cachedPath {
    switch (this) {
      case TDSRequestType.metar:
        return dataServerPath + "metars.cache.xml";
      case TDSRequestType.taf:
        return dataServerPath + "tafs.cache.xml";
      case TDSRequestType.station:
        return dataServerPath + 'stations.cache.xml';
    }
  }
}

class TDSRequest {
  final TDSRequestType type;

  TDSRequest(this.type);

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile() async {
    String link = type.cachedPath;
    try {
      Response response = await get(Uri.parse(link));
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
    String link = type.cachedPath + ".gz";
    try {
      var bytes;
      // read bytes
      Response response = await get(Uri.parse(link));
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

  filterFalseEntries(Map<String, TDSElement> elements) {
    elements.removeWhere((key, value) {
      return (value.latitude < -90 || value.latitude > 90);
    });
  }
}
