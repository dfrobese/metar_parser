import 'dart:convert';
import 'package:http/http.dart';
import 'package:archive/archive_io.dart';
import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/StationTDS.dart';
import 'package:xml/xml.dart';



abstract class TDSElement {

}


enum TDSRequest {
  metar, taf, station;
  final String dataServerPath = "https://aviationweather.gov/adds/dataserver_current/";

  String get token => this.name.toUpperCase();


  Type get type {
    switch (this) {
      case TDSRequest.metar:
        return MetarTDS;
      case TDSRequest.taf:
        return TafTDS;
      case TDSRequest.station:
        return StationTDS; // does not exist
    }
  }

   fromElement<TDSElement>(XmlElement element) {
    switch (this) {
      case TDSRequest.metar:
        return MetarTDS.fromElement(element);
      case TDSRequest.taf:
        return TafTDS.fromElement(element);
      case TDSRequest.station:
        return StationTDS.fromElement(element); // does not exist
    }
  }

  String get cachedPath {
    switch (this) {
      case TDSRequest.metar:
        return dataServerPath + "current/metars.cache.xml";
      case TDSRequest.taf:
        return dataServerPath + "current/tafs.cache.xml";
      case TDSRequest.station:
        return "assets/stations.xml"; // does not exist
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile() async {
    String link = cachedPath;
    try {
      switch (this) {
        case TDSRequest.metar:
        case TDSRequest.taf:
          Response response = await get(Uri.parse(link));
          return response.body;
        case TDSRequest.station:
          return "";
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
          Response response = await get(Uri.parse(link));
          bytes = response.bodyBytes.toList();
          break;
        case TDSRequest.station:
          return "";
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

