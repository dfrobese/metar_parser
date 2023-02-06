import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/test.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';



void main () async {
  test('Load Weather', () async {
    TDSRequest request = TDSRequest();
    var file = await request.readZippedFile(Config.metar);
    final metars = MetarTDS.parse(file);
    final eddv = metars['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    expect(eddv.wind.direction, eddv.moreWind.direction);
    expect(eddv.wind.speed, eddv.moreWind.speed);
  });

}