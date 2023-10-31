import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main () {
  test('Taf test', () async {
    TDSRequest request = TDSRequest.taf;
    var file = await request.readZippedFile();
    final Map<String, TafTDS> tafs = request.parse<TafTDS>(file);
    final eddv = tafs['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    print(eddv.raw_text);
  });

}