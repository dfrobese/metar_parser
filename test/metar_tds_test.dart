import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:test/test.dart';


void main () async {
  test('Load Weather', () async {
    TDSRequest request = TDSRequest();

    var file = await request.readFile(Config.metar);
    final metars = MetarTDS.parse(file);
    final eddv = metars.firstWhere((element) => element.station_id == 'EDDV');
    expect(eddv.station_id, 'EDDV');
    developer.log('eddv.station_id', name: 'de.frobese.vfrinfo');
    expect(eddv.wind.direction, eddv.moreWind.direction);
    expect(eddv.wind.speed, eddv.moreWind.speed);

  });

}