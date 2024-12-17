import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/raw_parser/metar_raw_parser.dart';
import 'package:metar_parser_dart/src/raw_parser/taf_raw.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main () {
  test('Taf test', () async {
    //EDDV single
    final eddvRawTaf = "EDDV 200500Z 2006/2106 26009KT 9999 SCT008 BKN020 TEMPO 2006/2010 BKN008 PROB30 TEMPO 2006/2014 3500 -SHSNRA BKN012TCU TEMPO 2014/2020 2500 SHSNRA BKN010CB PROB30 TEMPO 2016/2019 28015G30KT 1400 SHSNGS BKN006CB PROB30 TEMPO 2020/2101 2500 -SHSNRA BKN006TCU BECMG 2100/2102 23004KT TEMPO 2101/2106 4000 BR BKN008";
    final map = MetarTafRawParser.parseTafRawText(eddvRawTaf);
    final tafRaw = TafRaw.fromMap(map);
    expect(eddvRawTaf == tafRaw.rawText, true);

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

     // for all tafs
    tafs.values.forEach((element) {
      final rawOrg = element.rawText;
      final mapFromRaw = MetarTafRawParser.parseTafRawText(rawOrg);
      final tafFromRaw = TafRaw.fromMap(mapFromRaw);
      final rawRebuild = tafFromRaw.rawText;
      expect(rawOrg == rawRebuild, true);
      if (rawRebuild != rawOrg) {
        print("Raw not fitted for ${element.station_id}");
      }
    });
  });

}