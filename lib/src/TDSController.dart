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

  TDSRequest request;

  TDSController(this.request);

  /// Makes a full file request of all Metars
  Future<void> fullRequest() async {
    var content = await request.readZippedFile();
    final file = content.toString();
    if (file.length < 100) {
      developer.log('ERROR file not found');
      throw new TDSFetchDataException("An error occured, file not found");
    }
    final Map<String, TDSElement> elements = request.parse(file);
    tdsDict.addAll(elements);
    notifyListeners();
  }
}

class MetarController extends TDSController<MetarTDS>{
  MetarController() : super(TDSRequest.metar);
}


class TafController extends TDSController<TafTDS>{
  TafController() : super(TDSRequest.taf);
}

class StationController extends TDSController<StationTDS>{
  StationController() : super(TDSRequest.station);
}



