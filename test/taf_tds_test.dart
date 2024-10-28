import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main () {
  test('Taf test', () async {
    final Map<String, TafTDS> tafs = await TafController().fullRequest();
    final eddv = tafs['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    print(eddv.rawText);
    eddv.forecasts.forEach((forecast) {print("PROB ${forecast.probability} Change ${forecast.changeIndicator} Wind  ${forecast.windSpeedKt}");});
  });

}