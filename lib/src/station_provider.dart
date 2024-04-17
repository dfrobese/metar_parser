import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';


final stationProvider = FutureProvider<Map<String, StationTDS>>((ref) async {
  developer.log('#station_Provider fullRequest');
  final Map<String, StationTDS> tdsDict = Map();
  final TDSRequest request;

  request = TDSRequest(TDSRequestType.station);

  var content = await request.readZippedFile();
  final file = content.toString();
  if (file.length < 100) {
    developer.log('ERROR file not found');
    throw new TDSFetchDataException("An error occured, file not found");
  }
  final map = request.parse(file);

  tdsDict.addAll(map.cast<String, StationTDS>());

  return tdsDict;

});