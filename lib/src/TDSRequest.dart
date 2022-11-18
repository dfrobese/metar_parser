import 'package:http/http.dart';

enum Config {metar, taf, station}

class TDSRequest {

  String dataServerPath = "https://aviationweather.gov/adds/dataserver_current/";

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

  Future<String> readFile(Config config ) async {

    String link = cachedPath(config);

    Response response = await get(Uri.parse(link));
    return response.body;
  }


}