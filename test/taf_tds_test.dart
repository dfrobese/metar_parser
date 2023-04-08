import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/test.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';



void main () async {
  test('Load Weather', () async {
    TDSRequest request = TDSRequest.taf;
    var file = await request.readZippedFile();
    final Map<String, TafTDS> tafs = request.parse<TafTDS>(file);
    final eddv = tafs['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
  });

}