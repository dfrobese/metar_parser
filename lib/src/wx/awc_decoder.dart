import 'dart:math' as math;

import 'package:metar_parser_dart/src/flight_category.dart';
import 'package:metar_parser_dart/src/wx/wx_models.dart';
import 'package:xml/xml.dart';

/// Result of decoding one cache file: the usable entries and how many were
/// skipped because they could not be read.
class AwcDecoded<T> {
  const AwcDecoded(this.items, this.skipped);
  final List<T> items;
  final int skipped;
}

/// Decodes aviationweather.gov's cache files (`metars.cache.xml`,
/// `tafs.cache.xml`, `stations.cache.xml`) into the wx/v1 wire model.
///
/// The files already carry decoded fields, so this only converts units and
/// shapes: statute miles to metres, inches of mercury to hPa, `OVX` to a
/// `VV` layer. One unreadable entry is skipped, never the whole file.
class AwcDecoder {
  const AwcDecoder._();

  static const _metresPerMile = 1609.344;

  /// METARs and SPECIs of a `metars.cache.xml` document.
  static AwcDecoded<WxMetar> metars(String xml) =>
      _decodeAll(xml, 'METAR', metar);

  /// TAFs of a `tafs.cache.xml` document.
  static AwcDecoded<WxTaf> tafs(String xml) => _decodeAll(xml, 'TAF', taf);

  /// Stations of a `stations.cache.xml` document that issue a METAR or TAF.
  static AwcDecoded<WxStation> stations(String xml) =>
      _decodeAll(xml, 'Station', station);

  static AwcDecoded<T> _decodeAll<T>(
      String xml, String tag, T? Function(XmlElement) decode) {
    final items = <T>[];
    var skipped = 0;
    for (final element in XmlDocument.parse(xml).findAllElements(tag)) {
      try {
        final item = decode(element);
        if (item != null) items.add(item);
      } catch (_) {
        skipped++;
      }
    }
    return AwcDecoded(items, skipped);
  }

  /// One `<METAR>` element; null when it lacks station, time or position.
  static WxMetar? metar(XmlElement e) {
    final id = _text(e, 'station_id');
    final time = _text(e, 'observation_time');
    final lat = _double(e, 'latitude');
    final lon = _double(e, 'longitude');
    final raw = _text(e, 'raw_text');
    if (id == null || time == null || lat == null || lon == null || raw == null) {
      return null;
    }
    final clouds = _cloudsWithRawTypes(_clouds(e), raw);
    final visibility = _visibilityM(_text(e, 'visibility_statute_mi'), clouds);
    final ceiling = ceilingOf(clouds);
    final category = flightCategoryFromJson(_text(e, 'flight_category'));
    final altim = _double(e, 'altim_in_hg');
    return WxMetar(
      stationId: id,
      type: _text(e, 'metar_type') ?? 'METAR',
      observedAt: DateTime.parse(time).toUtc(),
      raw: raw,
      lat: lat,
      lon: lon,
      flightCategory: category != FlightCategory.NONE
          ? category
          : flightCategoryFor(visibilityM: visibility, ceilingFt: ceiling),
      wind: _wind(e, raw),
      visibilityM: visibility,
      ceilingFt: ceiling,
      clouds: clouds,
      weather: _weather(e),
      tempC: _double(e, 'temp_c'),
      dewpointC: _double(e, 'dewpoint_c'),
      qnhHpa: altim == null || altim <= 0 ? null : (altim * 33.8638866667).round(),
    );
  }

  /// One `<TAF>` element with its forecast periods.
  static WxTaf? taf(XmlElement e) {
    final id = _text(e, 'station_id');
    final issued = _text(e, 'issue_time');
    final from = _text(e, 'valid_time_from');
    final to = _text(e, 'valid_time_to');
    final lat = _double(e, 'latitude');
    final lon = _double(e, 'longitude');
    final raw = _text(e, 'raw_text');
    if (id == null || issued == null || from == null || to == null ||
        lat == null || lon == null || raw == null) {
      return null;
    }
    return WxTaf(
      stationId: id,
      issuedAt: DateTime.parse(issued).toUtc(),
      validFrom: DateTime.parse(from).toUtc(),
      validTo: DateTime.parse(to).toUtc(),
      raw: raw,
      lat: lat,
      lon: lon,
      periods: _periods(e.findElements('forecast').toList()),
    );
  }

  /// The periods of a TAF, each with the flight category of the conditions
  /// in force during it: a BASE or FM period sets them, BECMG changes the
  /// values it names, TEMPO and PROB deviate from them without changing them.
  static List<WxTafPeriod> _periods(List<XmlElement> forecasts) {
    int? prevailingVis;
    List<WxCloud>? prevailingClouds;
    final periods = <WxTafPeriod>[];
    for (final f in forecasts) {
      final indicator = _text(f, 'change_indicator');
      final probability = _int(f, 'probability');
      final change = indicator ?? (probability != null ? 'PROB' : 'BASE');
      final hasClouds = f.findElements('sky_condition').isNotEmpty ||
          _text(f, 'vert_vis_ft') != null;
      final clouds = hasClouds ? _clouds(f) : <WxCloud>[];
      final visText = _text(f, 'visibility_statute_mi');
      final vis = visText == null ? null : _visibilityM(visText, clouds);

      final effectiveVis = vis ?? (change == 'FM' || change == 'BASE' ? null : prevailingVis);
      final effectiveClouds =
          hasClouds ? clouds : (change == 'FM' || change == 'BASE' ? <WxCloud>[] : prevailingClouds ?? <WxCloud>[]);
      if (change == 'BASE' || change == 'FM') {
        prevailingVis = vis;
        prevailingClouds = clouds;
      } else if (change == 'BECMG') {
        if (vis != null) prevailingVis = vis;
        if (hasClouds) prevailingClouds = clouds;
      }

      periods.add(WxTafPeriod(
        from: DateTime.parse(_text(f, 'fcst_time_from')!).toUtc(),
        to: DateTime.parse(_text(f, 'fcst_time_to')!).toUtc(),
        change: change,
        probability: probability,
        wind: _wind(f, null),
        visibilityM: vis,
        ceilingFt: hasClouds ? ceilingOf(clouds) : null,
        clouds: clouds,
        weather: _weather(f),
        flightCategory: flightCategoryFor(
            visibilityM: effectiveVis, ceilingFt: ceilingOf(effectiveClouds)),
      ));
    }
    return periods;
  }

  /// One `<Station>` element; null unless it issues a METAR or TAF.
  static WxStation? station(XmlElement e) {
    final id = _text(e, 'icao_id') ?? _text(e, 'station_id');
    final lat = _double(e, 'latitude');
    final lon = _double(e, 'longitude');
    final types = e.getElement('site_type');
    final hasMetar = types?.getElement('METAR') != null;
    final hasTaf = types?.getElement('TAF') != null;
    if (id == null || lat == null || lon == null || !(hasMetar || hasTaf)) {
      return null;
    }
    final elevation = _double(e, 'elevation_m');
    return WxStation(
      id: id,
      name: _displayName(_text(e, 'site') ?? id),
      lat: lat,
      lon: lon,
      elevationFt: elevation == null ? null : (elevation * 3.28084).round(),
      country: _text(e, 'country'),
      hasMetar: hasMetar,
      hasTaf: hasTaf,
    );
  }

  /// Visibility in metres from the file's statute miles (`10+`, `6+`,
  /// `0.25`); 9999 for 10 km or more, and for CAVOK without a value.
  static int? _visibilityM(String? text, List<WxCloud> clouds) {
    if (text == null) {
      return clouds.any((c) => c.cover == 'CAVOK') ? 9999 : null;
    }
    final match = RegExp(r'^(\d+(?:\.\d+)?)(\+)?$').firstMatch(text.trim());
    if (match == null) return null;
    final miles = double.parse(match.group(1)!);
    if (match.group(2) != null && miles >= 6) return 9999;
    return math.min(9999, (miles * _metresPerMile).round());
  }

  /// Cloud layers; `OVX` (sky obscured) becomes `VV` with the vertical
  /// visibility as its base.
  static List<WxCloud> _clouds(XmlElement e) {
    final verticalVis = _int(e, 'vert_vis_ft');
    final layers = <WxCloud>[];
    for (final s in e.findElements('sky_condition')) {
      final cover = s.getAttribute('sky_cover');
      if (cover == null || cover.isEmpty) continue;
      final base = int.tryParse(s.getAttribute('cloud_base_ft_agl') ?? '');
      final type = s.getAttribute('cloud_type');
      layers.add(cover == 'OVX'
          ? WxCloud(cover: 'VV', baseFt: verticalVis ?? base)
          : WxCloud(cover: cover, baseFt: base, type: type));
    }
    if (verticalVis != null && !layers.any((c) => c.cover == 'VV')) {
      layers.add(WxCloud(cover: 'VV', baseFt: verticalVis));
    }
    return layers;
  }

  /// The METAR cache file leaves out cloud types; they are read from the
  /// coded groups (`BKN030CB`) and matched to the layer with that base.
  static List<WxCloud> _cloudsWithRawTypes(List<WxCloud> clouds, String raw) {
    final types = <String, String>{};
    for (final m in RegExp(r'\b(FEW|SCT|BKN|OVC)(\d{3})(CB|TCU)\b').allMatches(raw)) {
      types['${m.group(1)}${int.parse(m.group(2)!) * 100}'] = m.group(3)!;
    }
    if (types.isEmpty) return clouds;
    return [
      for (final c in clouds)
        c.type == null && types.containsKey('${c.cover}${c.baseFt}')
            ? WxCloud(cover: c.cover, baseFt: c.baseFt, type: types['${c.cover}${c.baseFt}'])
            : c
    ];
  }

  /// Wind group; null when the entry carries none. The variable sector is
  /// only in the coded text, so it is read from [raw] when given.
  static WxWind? _wind(XmlElement e, String? raw) {
    final dirText = _text(e, 'wind_dir_degrees');
    final speed = _int(e, 'wind_speed_kt');
    if (dirText == null && speed == null) return null;
    final variable = dirText == 'VRB';
    final sector = raw == null
        ? null
        : RegExp(r'\s(\d{3})V(\d{3})\s').firstMatch(' $raw ');
    return WxWind(
      directionDeg: variable ? null : int.tryParse(dirText ?? ''),
      variable: variable,
      speedKt: speed ?? 0,
      gustKt: _int(e, 'wind_gust_kt'),
      fromDeg: sector == null ? null : int.parse(sector.group(1)!),
      toDeg: sector == null ? null : int.parse(sector.group(2)!),
    );
  }

  static List<String> _weather(XmlElement e) {
    final text = _text(e, 'wx_string');
    if (text == null) return const [];
    return text.split(RegExp(r'\s+')).where((g) => g.isNotEmpty).toList();
  }

  /// Site names come in capitals from some sources (`HANNOVER`); those are
  /// title-cased, mixed-case names (`McCarran Intl`) are kept as they are.
  static String _displayName(String site) {
    if (site != site.toUpperCase()) return site;
    return site.toLowerCase().replaceAllMapped(
        RegExp(r"(^|[\s/\-(])([a-z])"), (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}');
  }

  static String? _text(XmlElement e, String name) {
    final text = e.getElement(name)?.innerText.trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double? _double(XmlElement e, String name) =>
      double.tryParse(_text(e, name) ?? '');

  static int? _int(XmlElement e, String name) {
    final value = _double(e, name);
    return value?.round();
  }
}
