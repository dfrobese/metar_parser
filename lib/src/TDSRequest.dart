import 'dart:convert';

import 'package:http/http.dart';
import 'dart:io';
import 'package:archive/archive_io.dart';

import 'dart:developer' as developer;

enum Config {metar, taf, station}


/// Class to manage the request against NOAA Metar/Taf  text data server
class TDSRequest {

  final String dataServerPath = "https://aviationweather.gov/adds/dataserver_current/";

  const TDSRequest();

  // return cached path
  String cachedPath(Config config) {
      switch (config) {
        case Config.metar:
          return dataServerPath + "current/metars.cache.xml";
        case Config.taf:
          return dataServerPath + "current/tafs.cache.xml";
        case Config.station:
          return dataServerPath + ""; // does not exist
      }
  }


  /// read file based Metar/Taf/Station information with all entries
  Future<String> readFile(Config config ) async {
    String link = cachedPath(config);
    try {
      Response response = await get(Uri.parse(link));
      return response.body;
    } on Exception catch(e) {
      return "";
    }
  }

  /// read file based Metar/Taf/Station information with all entries
  Future<String> readZippedFile(Config config ) async {
    String link = cachedPath(config) + ".gz";
    try {
      Response response = await get(Uri.parse(link));
      final bytes = response.bodyBytes.toList();
      final decoder = GZipDecoder();
       final result  = decoder.decodeBytes(bytes);
      String unzipped = utf8.decode(result);
       return unzipped;
    } on Exception catch(e) {
      return "";
    }
  }

}