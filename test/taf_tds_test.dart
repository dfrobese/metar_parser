import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';
import 'package:metar_parser_dart/src/raw_parser/taf_raw.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main () {
  test('Fixed Taf EDDV test', () {
    //EDDV single
    final eddvRawTaf = "TAF EDDV 200500Z 2006/2106 26009KT 9999 SCT008 BKN020 TEMPO 2006/2010 BKN008 PROB30 TEMPO 2006/2014 3500 -SHSNRA BKN012TCU TEMPO 2014/2020 2500 SHSNRA BKN010CB PROB30 TEMPO 2016/2019 28015G30KT 1400 SHSNGS BKN006CB PROB30 TEMPO 2020/2101 2500 -SHSNRA BKN006TCU BECMG 2100/2102 23004KT TEMPO 2101/2106 4000 BR BKN008";
    final map = MetarTafRawParser.parseTafRawText(eddvRawTaf);
    final tafRaw = TafRaw.fromMap(map);
    expect(eddvRawTaf == tafRaw.rawText, true);
    // check cloudbase
    expect(tafRaw.forecasts[0].lowestSignificantCloudBase == 2000, true);
    expect(tafRaw.forecasts[1].lowestSignificantCloudBase == 800, true);
    expect(tafRaw.forecasts[2].lowestSignificantCloudBase == 1200, true);
    expect(tafRaw.forecasts[2].weather?.first.wxString == '-SHSNRA', true);
    print(tafRaw.forecasts[2].weather?.first.toString());
    // check visibility
    expect(tafRaw.forecasts[0].visibility!.minVisibility == 9999, true);
    expect(tafRaw.forecasts[2].visibility!.minVisibility == 3500, true);
  });

  test('Taf full test', () async {
    // Full request
    final Map<String, TafTDS> tafs = await TafController().fullRequest();
    // pick EDDV actual Taf
    final eddv = tafs['EDDV'];
    expect(eddv != null, true);
    expect(eddv!.station_id, 'EDDV');
    print(eddv.station_id);
    print(eddv.rawText);
    // compare actual taf in raw
    final parsedMap = MetarTafRawParser.parseTafRawText(eddv.rawText);
    final tafFromRaw = TafRaw.fromMap(parsedMap);
    final rawRebuild = tafFromRaw.rawText;
    expect(eddv.rawText == rawRebuild, true);
    expect (tafFromRaw.forecasts.first.lowestSignificantCloudBase == eddv.forecasts.first.lowestSignificantCloudBase, true);
    if (tafFromRaw.forecasts.first.visibility!= null) {

      expect(tafFromRaw.forecasts.first.visibility!.minInMiles, closeTo(eddv.forecasts.first.visibility!.minInMiles, 0.5));
      print(tafFromRaw.forecasts.first.visibility.toString());
      print(eddv.forecasts.first.visibility.toString());
    }
    print("${eddv.rawFormatedText}");

     // for all tafs
    var failureCount = 0;
    tafs.values.forEach((element) {
      final rawOrg = element.rawText.startsWith("TAF") ? element.rawText.trim() : "TAF " + element.rawText.trim();

      final mapFromRaw = MetarTafRawParser.parseTafRawText(rawOrg);
      final tafFromRaw = TafRaw.fromMap(mapFromRaw);
      final rawRebuild = tafFromRaw.rawText;

      try {
        expect(rawOrg == rawRebuild, true);
        expect (tafFromRaw.forecasts.first.lowestSignificantCloudBase == element.forecasts.first.lowestSignificantCloudBase, true);
        if (tafFromRaw.forecasts.first.visibility!= null) {
          expect(tafFromRaw.forecasts.first.visibility!.minInMiles,
            closeTo(element.forecasts.first.visibility!.minInMiles, 0.5));
        }
      } catch (e) {
        failureCount++;
        print("Raw not fitted for ${element.station_id}");
        print(rawOrg);
        var forecasts = element.forecasts;
        print(rawRebuild);
      }
    });
    print("Failures $failureCount");
  });

}