import 'dart:developer' as developer;
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/MetarTDS.dart';
import 'package:metar_dart/metar_dart.dart';


class MetarFetchDataException implements Exception {
  final _message;
  MetarFetchDataException([this._message]);

  String toString() {
    if (_message == null) return "Exception";
    return "Exception: $_message";
  }
}


class MetarController {

  final Map<String, MetarTDS> metarDict = Map();
  final TDSRequest request = TDSRequest();

  MetarController();
  
  /// Makes a full file request of all Metars
  Future<void> fullRequest() async {
      var content = await request.readZippedFile(Config.metar);
      final file = content.toString();
      if (file.length < 100) {
          developer.log('ERROR file not found');
          throw new MetarFetchDataException("An error occured, file not found");
      }
      final Map<String, MetarTDS> metars = MetarTDS.parse(file);
      metarDict.addAll(metars);
  }
}


