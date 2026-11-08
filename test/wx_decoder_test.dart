import 'dart:convert';

import 'package:metar_parser_dart/wx_api.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

String _doc(String body) =>
    '<?xml version="1.0" encoding="UTF-8"?><response><data>$body</data></response>';

// Real entries from aviationweather.gov's cache files, 2026-11-08.
const _eddhMetar = '<METAR><raw_text>METAR EDDH 081150Z AUTO 14008KT 9999 OVC011 07/04 Q1023 TEMPO BKN015</raw_text>'
    '<station_id>EDDH</station_id><observation_time>2026-11-08T11:50:00.000Z</observation_time>'
    '<latitude>53.6330</latitude><longitude>9.9880</longitude><temp_c>7</temp_c><dewpoint_c>4</dewpoint_c>'
    '<wind_dir_degrees>140</wind_dir_degrees><wind_speed_kt>8</wind_speed_kt>'
    '<visibility_statute_mi>6+</visibility_statute_mi><altim_in_hg>30.21</altim_in_hg>'
    '<quality_control_flags><auto>TRUE</auto></quality_control_flags>'
    '<sky_condition sky_cover="OVC" cloud_base_ft_agl="1100"/><flight_category>MVFR</flight_category>'
    '<metar_type>METAR</metar_type><elevation_m>8</elevation_m></METAR>';

const _eddvTaf = '<TAF><raw_text><![CDATA[TAF EDDV 081100Z 0812/0912 14004KT 9999 BKN030 TEMPO 0819/0909 2500 BCFG PROB30 TEMPO 0821/0908 0500 FG OVC001]]></raw_text>'
    '<station_id>EDDV</station_id><issue_time>2026-11-08T11:00:00.000Z</issue_time>'
    '<bulletin_time>2026-11-08T11:00:00.000Z</bulletin_time><valid_time_from>2026-11-08T12:00:00.000Z</valid_time_from>'
    '<valid_time_to>2026-11-09T12:00:00.000Z</valid_time_to><latitude>52.4660</latitude><longitude>9.6800</longitude>'
    '<elevation_m>53.0000</elevation_m>'
    '<forecast><fcst_time_from>2026-11-08T12:00:00.000Z</fcst_time_from><fcst_time_to>2026-11-09T12:00:00.000Z</fcst_time_to>'
    '<wind_dir_degrees>140</wind_dir_degrees><wind_speed_kt>4</wind_speed_kt><visibility_statute_mi>6+</visibility_statute_mi>'
    '<sky_condition sky_cover="BKN" cloud_base_ft_agl="3000"/></forecast>'
    '<forecast><fcst_time_from>2026-11-08T19:00:00.000Z</fcst_time_from><fcst_time_to>2026-11-09T09:00:00.000Z</fcst_time_to>'
    '<change_indicator>TEMPO</change_indicator><visibility_statute_mi>1.55</visibility_statute_mi><wx_string>BCFG</wx_string></forecast>'
    '<forecast><fcst_time_from>2026-11-08T21:00:00.000Z</fcst_time_from><fcst_time_to>2026-11-09T08:00:00.000Z</fcst_time_to>'
    '<change_indicator>TEMPO</change_indicator><probability>30</probability><visibility_statute_mi>0.31</visibility_statute_mi>'
    '<wx_string>FG</wx_string><sky_condition sky_cover="OVC" cloud_base_ft_agl="100"/></forecast></TAF>';

const _eddhStation = '<Station><station_id>EDDH</station_id><icao_id>EDDH</icao_id><iata_id>HAM</iata_id>'
    '<wmo_id>10147</wmo_id><faa_id/><latitude>53.6330</latitude><longitude>9.9880</longitude>'
    '<elevation_m>8</elevation_m><site>Hamburg Arpt</site><state>HH</state><country>DE</country>'
    '<site_type><METAR/><TAF/></site_type></Station>';

String _metar({
  String raw = 'METAR XXXX 081150Z 00000KT 9999 FEW030 10/05 Q1013',
  String extra = '',
}) =>
    '<METAR><raw_text>$raw</raw_text><station_id>XXXX</station_id>'
    '<observation_time>2026-11-08T11:50:00.000Z</observation_time>'
    '<latitude>50.0</latitude><longitude>8.0</longitude>$extra</METAR>';

void main() {
  group('METAR', () {
    test('a real report decodes to metric values', () {
      final m = AwcDecoder.metars(_doc(_eddhMetar)).items.single;
      expect(m.stationId, 'EDDH');
      expect(m.observedAt, DateTime.utc(2026, 11, 8, 11, 50));
      expect(m.flightCategory, FlightCategory.MVFR);
      expect(m.wind!.directionDeg, 140);
      expect(m.wind!.speedKt, 8);
      expect(m.visibilityM, 9999);
      expect(m.ceilingFt, 1100);
      expect(m.qnhHpa, 1023);
      expect(m.tempC, 7);
    });

    test('decimal visibility is kept, not truncated', () {
      final m = AwcDecoder.metar(
          _xml(_metar(extra: '<visibility_statute_mi>0.25</visibility_statute_mi>')))!;
      expect(m.visibilityM, 402);
    });

    test('missing values are null, not 0', () {
      final m = AwcDecoder.metar(_xml(_metar()))!;
      expect(m.tempC, isNull);
      expect(m.qnhHpa, isNull);
      expect(m.visibilityM, isNull);
      expect(m.wind, isNull);
    });

    test('variable wind and its sector', () {
      final m = AwcDecoder.metar(_xml(_metar(
          raw: 'METAR XXXX 081150Z VRB03KT 220V290 9999 FEW030 10/05 Q1013',
          extra: '<wind_dir_degrees>VRB</wind_dir_degrees><wind_speed_kt>3</wind_speed_kt>')))!;
      expect(m.wind!.variable, isTrue);
      expect(m.wind!.directionDeg, isNull);
      expect(m.wind!.fromDeg, 220);
      expect(m.wind!.toDeg, 290);
    });

    test('cloud type comes from the coded text, OVX becomes VV', () {
      final cb = AwcDecoder.metar(_xml(_metar(
          raw: 'METAR XXXX 081150Z 27015KT 9999 SCT020 BKN030CB 10/05 Q1013',
          extra: '<sky_condition sky_cover="SCT" cloud_base_ft_agl="2000"/>'
              '<sky_condition sky_cover="BKN" cloud_base_ft_agl="3000"/>')))!;
      expect(cb.clouds.last.type, 'CB');
      expect(cb.clouds.first.type, isNull);

      final vv = AwcDecoder.metar(_xml(_metar(
          extra: '<vert_vis_ft>200</vert_vis_ft><sky_condition sky_cover="OVX" cloud_base_ft_agl="0"/>')))!;
      expect(vv.clouds.single.cover, 'VV');
      expect(vv.ceilingFt, 200);
      expect(vv.flightCategory, FlightCategory.LIFR);
    });

    test('an entry without position is skipped, the rest kept', () {
      final decoded = AwcDecoder.metars(_doc('$_eddhMetar<METAR><raw_text>X</raw_text><station_id>X</station_id></METAR>'));
      expect(decoded.items, hasLength(1));
    });
  });

  group('TAF', () {
    test('periods and their effective flight categories', () {
      final t = AwcDecoder.tafs(_doc(_eddvTaf)).items.single;
      expect(t.periods.map((p) => p.change), ['BASE', 'TEMPO', 'TEMPO']);
      expect(t.periods[0].flightCategory, FlightCategory.MVFR); // BKN030
      // TEMPO 2500 BCFG: own visibility, ceiling still BKN030 from the base.
      expect(t.periods[1].visibilityM, 2494);
      expect(t.periods[1].ceilingFt, isNull);
      expect(t.periods[1].flightCategory, FlightCategory.IFR);
      expect(t.periods[2].probability, 30);
      expect(t.periods[2].flightCategory, FlightCategory.LIFR);
    });

    test('prevailing period and next change', () {
      final t = AwcDecoder.tafs(_doc(_eddvTaf)).items.single;
      final noon = DateTime.utc(2026, 11, 8, 14);
      final now = t.prevailingAt(noon)!;
      expect(now.change, 'BASE');
      expect(t.nextChangeAfter(noon, now)!.flightCategory, FlightCategory.IFR);
    });
  });

  test('stations: only those with METAR or TAF, names kept or title-cased', () {
    final decoded = AwcDecoder.stations(_doc('$_eddhStation<Station><station_id>32012</station_id><latitude>19.6</latitude>'
        '<longitude>-85.5</longitude><site>Buoy</site><site_type/></Station>'));
    final s = decoded.items.single;
    expect(s.id, 'EDDH');
    expect(s.name, 'Hamburg Arpt');
    expect(s.elevationFt, 26);
    expect(s.hasMetar && s.hasTaf, isTrue);
  });

  test('JSON round trip keeps every field', () {
    final m = AwcDecoder.metars(_doc(_eddhMetar)).items.single;
    final t = AwcDecoder.tafs(_doc(_eddvTaf)).items.single;
    final m2 = WxMetar.fromJson(jsonDecode(jsonEncode(m.toJson())) as Map<String, Object?>);
    final t2 = WxTaf.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, Object?>);
    expect(jsonEncode(m2.toJson()), jsonEncode(m.toJson()));
    expect(jsonEncode(t2.toJson()), jsonEncode(t.toJson()));
    expect(m.toJson()['observed_at'], '2026-11-08T11:50:00Z');
    expect(m.toJson()['flight_category'], 'MVFR');
  });

  test('flight category thresholds', () {
    expect(flightCategoryFor(), FlightCategory.NONE);
    expect(flightCategoryFor(visibilityM: 9999, ceilingFt: 5000), FlightCategory.VFR);
    expect(flightCategoryFor(visibilityM: 9999, ceilingFt: 3000), FlightCategory.MVFR);
    expect(flightCategoryFor(visibilityM: 4000), FlightCategory.IFR);
    expect(flightCategoryFor(ceilingFt: 400), FlightCategory.LIFR);
  });
}

// A single element parsed on its own, for the per-entry decoders.
XmlElement _xml(String element) => XmlDocument.parse(element).rootElement;
