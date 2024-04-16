import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/extension/NotifyChanges.dart';



class TDSFetchDataException implements Exception {
  final _message;
  TDSFetchDataException([this._message]);

  String toString() {
    if (_message == null) return "Exception";
    return "Exception: $_message";
  }
}

class TDSController<TDSElement> extends NotifyChanges {

  final Map<String, TDSElement> tdsDict = Map();

  final TDSRequest request;

  TDSController(TDSRequestType type) :
    request = TDSRequest(type);


  /// Makes a full file request of all Metars
  Future<Map<String, TDSElement>> fullRequest() async {
    developer.log('#Metar_Parser fullRequest');
    var content = await request.readZippedFile();
    final file = content.toString();
    if (file.length < 100) {
      developer.log('ERROR file not found');
      throw new TDSFetchDataException("An error occured, file not found");
    }
    final map = request.parse(file);

    tdsDict.addAll(map.cast<String, TDSElement>());
    notifyListeners();
    return tdsDict;
  }


}



class MetarController extends TDSController<MetarTDS>{
  MetarController() : super(TDSRequestType.metar);
}


class TafController extends TDSController<TafTDS>{
  TafController() : super(TDSRequestType.taf);

}

class StationController extends TDSController<StationTDS>{
  StationController() : super(TDSRequestType.station);

}



