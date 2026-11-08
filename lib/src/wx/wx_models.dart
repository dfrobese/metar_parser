import 'package:metar_parser_dart/src/flight_category.dart';

/// Wire model of the VFRInfo weather API (wx/v1).
///
/// The server builds these from aviationweather.gov's cache files and writes
/// them with [toJson]; clients read them back with `fromJson`. Units sit in
/// the field names (`_kt`, `_m`, `_ft`, `_hpa`, `_c`); a missing value is
/// null, never 0. Within v1 fields are only added, so `fromJson` ignores
/// keys it does not know.

/// JSON name of a flight category; `NONE` travels as `UNKNOWN`.
String flightCategoryToJson(FlightCategory category) =>
    category == FlightCategory.NONE ? 'UNKNOWN' : category.name;

/// Flight category from its JSON name; anything unknown is `NONE`.
FlightCategory flightCategoryFromJson(Object? name) => FlightCategory.values
    .firstWhere((c) => c.name == name, orElse: () => FlightCategory.NONE);

/// Flight category from visibility and ceiling, NOAA thresholds in metric:
/// LIFR below 500 ft or 1 SM, IFR below 1000 ft or 3 SM, MVFR up to 3000 ft
/// or 5 SM, VFR above. Either value may be missing; both missing is `NONE`.
FlightCategory flightCategoryFor({int? visibilityM, int? ceilingFt}) {
  if (visibilityM == null && ceilingFt == null) return FlightCategory.NONE;
  bool below(int? value, int limit) => value != null && value < limit;
  bool atMost(int? value, int limit) => value != null && value <= limit;
  if (below(ceilingFt, 500) || below(visibilityM, 1609)) {
    return FlightCategory.LIFR;
  }
  if (below(ceilingFt, 1000) || below(visibilityM, 4828)) {
    return FlightCategory.IFR;
  }
  if (atMost(ceilingFt, 3000) || atMost(visibilityM, 8047)) {
    return FlightCategory.MVFR;
  }
  return FlightCategory.VFR;
}

/// ISO 8601 in UTC, whole seconds: `2026-11-08T11:50:00Z`.
String wxTime(DateTime time) => time
    .toUtc()
    .toIso8601String()
    .replaceFirst(RegExp(r'\.\d+Z$'), 'Z');

DateTime _time(Object? value) => DateTime.parse(value as String).toUtc();
int? _int(Object? value) => (value as num?)?.toInt();
double? _double(Object? value) => (value as num?)?.toDouble();

/// Wind group of a report or a TAF period.
class WxWind {
  const WxWind({
    this.directionDeg,
    this.variable = false,
    required this.speedKt,
    this.gustKt,
    this.fromDeg,
    this.toDeg,
  });

  /// Null when [variable].
  final int? directionDeg;
  final bool variable;
  final int speedKt;
  final int? gustKt;

  /// Variable sector, e.g. 220 and 290 for `220V290`.
  final int? fromDeg;
  final int? toDeg;

  factory WxWind.fromJson(Map<String, Object?> json) => WxWind(
        directionDeg: _int(json['direction_deg']),
        variable: json['variable'] as bool? ?? false,
        speedKt: _int(json['speed_kt']) ?? 0,
        gustKt: _int(json['gust_kt']),
        fromDeg: _int(json['from_deg']),
        toDeg: _int(json['to_deg']),
      );

  Map<String, Object?> toJson() => {
        'direction_deg': directionDeg,
        'variable': variable,
        'speed_kt': speedKt,
        'gust_kt': gustKt,
        'from_deg': fromDeg,
        'to_deg': toDeg,
      };
}

/// One cloud layer. [cover] is `FEW`, `SCT`, `BKN`, `OVC`, `VV`, `SKC`,
/// `CLR`, `NSC` or `CAVOK`; [type] is `CB`, `TCU` or null.
class WxCloud {
  const WxCloud({required this.cover, this.baseFt, this.type});

  final String cover;

  /// Feet above ground; null for the covers that carry no base.
  final int? baseFt;
  final String? type;

  /// Whether this layer counts as a ceiling.
  bool get isCeiling =>
      baseFt != null && (cover == 'BKN' || cover == 'OVC' || cover == 'VV');

  factory WxCloud.fromJson(Map<String, Object?> json) => WxCloud(
        cover: json['cover'] as String,
        baseFt: _int(json['base_ft']),
        type: json['type'] as String?,
      );

  Map<String, Object?> toJson() =>
      {'cover': cover, 'base_ft': baseFt, 'type': type};
}

/// Lowest ceiling of [clouds], or null.
int? ceilingOf(List<WxCloud> clouds) {
  int? lowest;
  for (final layer in clouds) {
    if (layer.isCeiling && (lowest == null || layer.baseFt! < lowest)) {
      lowest = layer.baseFt;
    }
  }
  return lowest;
}

List<WxCloud> _clouds(Object? json) => [
      for (final c in (json as List?) ?? const []) WxCloud.fromJson(c as Map<String, Object?>)
    ];

List<String> _strings(Object? json) =>
    [for (final s in (json as List?) ?? const []) s as String];

/// A METAR or SPECI.
class WxMetar {
  const WxMetar({
    this.seq = 0,
    required this.stationId,
    required this.type,
    required this.observedAt,
    required this.raw,
    required this.lat,
    required this.lon,
    this.distanceKm,
    required this.flightCategory,
    this.wind,
    this.visibilityM,
    this.ceilingFt,
    this.clouds = const [],
    this.weather = const [],
    this.tempC,
    this.dewpointC,
    this.qnhHpa,
  });

  /// Assigned by the server when the report is stored; 0 before.
  final int seq;
  final String stationId;

  /// `METAR` or `SPECI`.
  final String type;
  final DateTime observedAt;
  final String raw;
  final double lat;
  final double lon;

  /// Only set in answers to a position query.
  final double? distanceKm;
  final FlightCategory flightCategory;
  final WxWind? wind;

  /// 9999 means 10 km or more.
  final int? visibilityM;
  final int? ceilingFt;
  final List<WxCloud> clouds;

  /// Coded groups as reported, e.g. `-SHRA`, `BR`.
  final List<String> weather;
  final double? tempC;
  final double? dewpointC;
  final int? qnhHpa;

  factory WxMetar.fromJson(Map<String, Object?> json) => WxMetar(
        seq: _int(json['seq']) ?? 0,
        stationId: json['station_id'] as String,
        type: json['type'] as String? ?? 'METAR',
        observedAt: _time(json['observed_at']),
        raw: json['raw'] as String,
        lat: _double(json['lat'])!,
        lon: _double(json['lon'])!,
        distanceKm: _double(json['distance_km']),
        flightCategory: flightCategoryFromJson(json['flight_category']),
        wind: json['wind'] == null
            ? null
            : WxWind.fromJson(json['wind'] as Map<String, Object?>),
        visibilityM: _int(json['visibility_m']),
        ceilingFt: _int(json['ceiling_ft']),
        clouds: _clouds(json['clouds']),
        weather: _strings(json['weather']),
        tempC: _double(json['temp_c']),
        dewpointC: _double(json['dewpoint_c']),
        qnhHpa: _int(json['qnh_hpa']),
      );

  /// JSON as the API sends it. `seq` is left out while it is 0, so the
  /// server can store the report before it has a number.
  Map<String, Object?> toJson() => {
        if (seq != 0) 'seq': seq,
        'station_id': stationId,
        'type': type,
        'observed_at': wxTime(observedAt),
        'raw': raw,
        'lat': lat,
        'lon': lon,
        if (distanceKm != null) 'distance_km': distanceKm,
        'flight_category': flightCategoryToJson(flightCategory),
        'wind': wind?.toJson(),
        'visibility_m': visibilityM,
        'ceiling_ft': ceilingFt,
        'clouds': [for (final c in clouds) c.toJson()],
        'weather': weather,
        'temp_c': tempC,
        'dewpoint_c': dewpointC,
        'qnh_hpa': qnhHpa,
      };
}

/// One TAF period. Values are null where the period does not change them;
/// [flightCategory] is computed from the conditions in force during it.
class WxTafPeriod {
  const WxTafPeriod({
    required this.from,
    required this.to,
    required this.change,
    this.probability,
    this.wind,
    this.visibilityM,
    this.ceilingFt,
    this.clouds = const [],
    this.weather = const [],
    required this.flightCategory,
  });

  final DateTime from;
  final DateTime to;

  /// `BASE`, `FM`, `BECMG`, `TEMPO` or `PROB`.
  final String change;

  /// 30 or 40, or null.
  final int? probability;
  final WxWind? wind;
  final int? visibilityM;
  final int? ceilingFt;
  final List<WxCloud> clouds;
  final List<String> weather;
  final FlightCategory flightCategory;

  /// Whether this period replaces the prevailing conditions (as opposed to
  /// a temporary or probable deviation from them).
  bool get isPrevailing => change == 'BASE' || change == 'FM' || change == 'BECMG';

  factory WxTafPeriod.fromJson(Map<String, Object?> json) => WxTafPeriod(
        from: _time(json['from']),
        to: _time(json['to']),
        change: json['change'] as String,
        probability: _int(json['probability']),
        wind: json['wind'] == null
            ? null
            : WxWind.fromJson(json['wind'] as Map<String, Object?>),
        visibilityM: _int(json['visibility_m']),
        ceilingFt: _int(json['ceiling_ft']),
        clouds: _clouds(json['clouds']),
        weather: _strings(json['weather']),
        flightCategory: flightCategoryFromJson(json['flight_category']),
      );

  Map<String, Object?> toJson() => {
        'from': wxTime(from),
        'to': wxTime(to),
        'change': change,
        'probability': probability,
        'wind': wind?.toJson(),
        'visibility_m': visibilityM,
        'ceiling_ft': ceilingFt,
        'clouds': [for (final c in clouds) c.toJson()],
        'weather': weather,
        'flight_category': flightCategoryToJson(flightCategory),
      };
}

/// A TAF with its periods in time order.
class WxTaf {
  const WxTaf({
    this.seq = 0,
    required this.stationId,
    required this.issuedAt,
    required this.validFrom,
    required this.validTo,
    required this.raw,
    required this.lat,
    required this.lon,
    this.periods = const [],
  });

  final int seq;
  final String stationId;
  final DateTime issuedAt;
  final DateTime validFrom;
  final DateTime validTo;
  final String raw;
  final double lat;
  final double lon;
  final List<WxTafPeriod> periods;

  /// The prevailing period in force at [time] (the last BASE, FM or BECMG
  /// that has started), or null outside the validity.
  WxTafPeriod? prevailingAt(DateTime time) {
    WxTafPeriod? found;
    for (final p in periods) {
      if (p.isPrevailing && !p.from.isAfter(time) && p.to.isAfter(time)) {
        found = p;
      }
    }
    return found;
  }

  /// The first period after or overlapping [time], other than [current],
  /// whose flight category differs from [current]'s.
  WxTafPeriod? nextChangeAfter(DateTime time, WxTafPeriod? current) {
    for (final p in periods) {
      if (identical(p, current) || !p.to.isAfter(time)) continue;
      if (current == null || p.flightCategory != current.flightCategory) {
        return p;
      }
    }
    return null;
  }

  factory WxTaf.fromJson(Map<String, Object?> json) => WxTaf(
        seq: _int(json['seq']) ?? 0,
        stationId: json['station_id'] as String,
        issuedAt: _time(json['issued_at']),
        validFrom: _time(json['valid_from']),
        validTo: _time(json['valid_to']),
        raw: json['raw'] as String,
        lat: _double(json['lat'])!,
        lon: _double(json['lon'])!,
        periods: [
          for (final p in (json['periods'] as List?) ?? const [])
            WxTafPeriod.fromJson(p as Map<String, Object?>)
        ],
      );

  Map<String, Object?> toJson() => {
        if (seq != 0) 'seq': seq,
        'station_id': stationId,
        'issued_at': wxTime(issuedAt),
        'valid_from': wxTime(validFrom),
        'valid_to': wxTime(validTo),
        'raw': raw,
        'lat': lat,
        'lon': lon,
        'periods': [for (final p in periods) p.toJson()],
      };
}

/// A weather station. No airport data: that comes from the AIP service.
class WxStation {
  const WxStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.elevationFt,
    this.country,
    this.hasMetar = false,
    this.hasTaf = false,
  });

  final String id;
  final String name;
  final double lat;
  final double lon;
  final int? elevationFt;
  final String? country;
  final bool hasMetar;
  final bool hasTaf;

  factory WxStation.fromJson(Map<String, Object?> json) => WxStation(
        id: json['id'] as String,
        name: json['name'] as String,
        lat: _double(json['lat'])!,
        lon: _double(json['lon'])!,
        elevationFt: _int(json['elevation_ft']),
        country: json['country'] as String?,
        hasMetar: json['has_metar'] as bool? ?? false,
        hasTaf: json['has_taf'] as bool? ?? false,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'elevation_ft': elevationFt,
        'country': country,
        'has_metar': hasMetar,
        'has_taf': hasTaf,
      };
}
