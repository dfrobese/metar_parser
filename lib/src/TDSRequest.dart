import 'dart:convert';
import 'package:http/http.dart';
import 'package:archive/archive_io.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/StationTDS.dart';
import 'package:xml/xml.dart';



abstract class TDSElement {

}


enum TDSRequest {
  metar, taf, station;
//  final String dataServerPath = "https://aviationweather.gov/adds/dataserver_current/";
//  final String dataServerPath = "https://aviationweather-bldr.ncep.noaa.gov/adds/dataserver_current/current/";
  final String dataServerPath = "https://aviationweather.gov/data/cache/";

  String get token {
    switch (this) {
      case TDSRequest.metar:
      case TDSRequest.taf:
        return this.name.toUpperCase();
      case TDSRequest.station:
        return "Station";
    }
  }


  Type get type {
    switch (this) {
      case TDSRequest.metar:
        return MetarTDS;
      case TDSRequest.taf:
        return TafTDS;
      case TDSRequest.station:
        return StationTDS;
    }
  }

   fromElement<TDSElement>(XmlElement element) {
    switch (this) {
      case TDSRequest.metar:
        return MetarTDS.fromElement(element);
      case TDSRequest.taf:
        return TafTDS.fromElement(element);
      case TDSRequest.station:
        return StationTDS.fromElement(element);
    }
  }

  String get cachedPath {
    switch (this) {
      case TDSRequest.metar:
        return dataServerPath + "metars.cache.xml";
      case TDSRequest.taf:
        return dataServerPath + "tafs.cache.xml";
      case TDSRequest.station:
        return dataServerPath + 'stations.cache.xml';
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile() async {
    String link = cachedPath;
    try {
      switch (this) {
        case TDSRequest.metar:
        case TDSRequest.taf:
        case TDSRequest.station:
          Response response = await get(Uri.parse(link));
          return response.body;
      }
    } on Exception catch(e) {
      return "";
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readZippedFile() async {
    String link = cachedPath + ".gz";
    try {
      var bytes;
      switch (this) {
        case TDSRequest.metar:
        case TDSRequest.taf:
        case TDSRequest.station:
          Response response = await get(Uri.parse(link));
          bytes = response.bodyBytes.toList();
          break;
      }
      final decoder = GZipDecoder();
      final result  = decoder.decodeBytes(bytes);
      String unzipped = utf8.decode(result);
      return unzipped;
    } on Exception catch(e) {
      return "";
    }
  }

  Map<String, TDSElement> parse<TDSElement>(String body) {
    if (body.length < 1) {
      throw TDSFetchDataException("No connection");
    }
    var document = XmlDocument.parse(body);
    var root = document.getElement('data');
    final elements = document.findAllElements(token);
    final map = Map<String, TDSElement>.fromIterable(elements,
        key: (item) => item.getElement('station_id')?.text!,
        value: (item) => this.fromElement<TDSElement>(item) );
    return map;
  }
}

