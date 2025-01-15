import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart';
import 'package:archive/archive_io.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/tds_parser/station_tds.dart';
import 'package:xml/xml.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

abstract  class TDSElement {
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
  final String dataServerPath = "https://aviationweather.gov/data/cache/";

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
      return response.body;
    } on Exception catch(e) {
      final msg = "Read file from url $link failed";
      developer.log('ERROR $msg');
      return msg;
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String?> readZippedFile() async {
    String link = type.cachedPath + ".gz";
    try {
      var bytes;
      // read bytes
      Response response = await get(Uri.parse(link));
      bytes = response.bodyBytes.toList();
      // unzip file
      var decoder;
      if (kIsWeb) {
        // Handle web-specific logic
        decoder = GZipDecoderWeb();
      } else {
        decoder = GZipDecoder();
      }
      final result = decoder.decodeBytes(bytes);
      String unzipped = utf8.decode(result);
      return unzipped;
    } on Exception catch (e) {
      developer.log("Read zipped file from url $link failed");
      return null;
    }
  }

  Map<String, TDSElement> parse(String body) {
    if (body.length < 1) {
      throw TDSFetchDataException("No connection");
    }
    var document = XmlDocument.parse(body);
    var root = document.getElement('data');
    final elements = document.findAllElements(type.token);
    var map = Map<String, TDSElement>.fromIterable(elements,
        key: (item) => item.getElement('station_id')?.text!,
        value: (item) => type.fromElement<TDSElement>(item) );

    filterFalseEntries(map);
    return map;
  }

  filterFalseEntries(Map<String, TDSElement> elements)  {
    elements.removeWhere((key, value) {
      return (value.latitude < -90 || value.latitude > 90);});
  }

}

