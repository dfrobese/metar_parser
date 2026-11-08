import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/cloud_coverage.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

TafTDS _taf(String raw) => TafTDS.fromXml(XmlDocument.parse('''
<TAF>
  <raw_text>$raw</raw_text>
  <station_id>EDDV</station_id>
  <issue_time>2024-02-20T05:00:00Z</issue_time>
  <latitude>52.46</latitude>
  <longitude>9.68</longitude>
</TAF>''').rootElement);

void main() {
  group('WindComponent', () {
    test('wind straight down the runway is all headwind', () {
      final c = WindComponent.forRunway(const Wind(false, 270, 15), 270);
      expect(c.headwind, 15);
      expect(c.crosswind, 0);
    });

    test('wind from behind is a negative headwind', () {
      final c = WindComponent.forRunway(const Wind(false, 90, 10), 270);
      expect(c.headwind, -10);
    });

    test('wind from the right is a positive crosswind', () {
      final c = WindComponent.forRunway(const Wind(false, 360, 20), 270);
      expect(c.crosswind, 20);
      expect(c.headwind, 0);
    });
  });

  group('text', () {
    test('wind group', () {
      expect(const Wind(false, 0, 0).text, 'Calm');
      expect(const Wind(false, 90, 8).text, '090/8 kt');
      expect(const Wind(true, 0, 3).text, 'VRB/3 kt');
      expect(const Wind(false, 280, 15, 30).text, '280/15G30 kt');
    });

    test('QNH in hPa', () {
      expect(qnhHpaText(29.92), '1013 hPa');
      expect(qnhHpaText(0), '-');
    });

    test('visibility in metric units', () {
      expect(metricVisibilityText(null), '-');
      expect(metricVisibilityText(10), 'over 10 km');
      expect(metricVisibilityText(3), '4.8 km');
      expect(metricVisibilityText(0.5), '805 m');
    });

    test('cloud layer', () {
      expect(CloudLayer.from(CloudCoverage.BKN, 1200).text, 'BKN 1200 ft');
      expect(CloudLayer.from(CloudCoverage.CAVOK, 0).text, 'CAVOK');
    });
  });

  group('forecastSummaries', () {
    test('one summary per period, qualifiers and gusts carried over', () {
      final taf = _taf('TAF EDDV 200500Z 2006/2106 26009KT 9999 SCT008 BKN020 '
          'PROB30 TEMPO 2016/2019 28015G30KT 1400 SHSNGS BKN006CB '
          'BECMG 2100/2102 23004KT');
      final periods = taf.forecastSummaries!;
      expect(periods, hasLength(3));

      expect(periods[0].qualifier, '');
      expect(periods[0].windDirectionDeg, 260);
      expect(periods[0].windGustKt, isNull);

      final tempo = periods.firstWhere((p) => p.windGustKt != null);
      expect(tempo.qualifier, contains('30%'));
      expect(tempo.windGustKt, 30);
    });

    test('a period without a wind group yields null wind instead of throwing',
        () {
      final taf =
          _taf('TAF EDDV 200500Z 2006/2106 26009KT 9999 SCT020 TEMPO 2006/2010 BKN008');
      final tempo = taf.forecastSummaries!.last;
      expect(tempo.qualifier, 'TEMPO');
      expect(tempo.windSpeedKt, isNull);
    });
  });

  test('qualifierText', () {
    expect(qualifierText('TAF', 100), '');
    expect(qualifierText('TEMPO', 100), 'TEMPO');
    expect(qualifierText('PROB', 30), 'PROB 30%');
  });
}
