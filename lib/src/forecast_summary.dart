import 'package:metar_parser_dart/src/flight_category.dart';
import 'package:metar_parser_dart/src/tds_parser/taf_tds.dart';

/// One TAF period, reduced to the values a display needs.
///
/// Built from the raw-parsed forecast, whose type is internal to this
/// package, so callers get a stable type without importing `src/`.
class ForecastSummary {
  const ForecastSummary({
    required this.from,
    required this.to,
    required this.category,
    this.windDirectionDeg,
    this.windSpeedKt,
    this.windGustKt,
    this.qualifier = '',
  });

  /// Start and end of the period, UTC.
  final DateTime from;
  final DateTime to;
  final FlightCategory category;

  /// Null when the period carries no wind group.
  final int? windDirectionDeg;
  final double? windSpeedKt;

  /// Null when the period carries no gust group, which is the common case.
  final double? windGustKt;

  /// `PROB30`, `TEMPO`, `BECMG`, `FM` … empty for the base period.
  final String qualifier;
}

/// Display summaries of a TAF's periods.
extension TafForecastSummaries on TafTDS {
  /// One [ForecastSummary] per period, in time order; null when the raw TAF
  /// cannot be decoded at all.
  ///
  /// Groups a period does not carry come out null rather than throwing:
  /// `ForecastRaw.wind` is declared `Wind?`, but its initialiser calls
  /// `Wind.parse` on an empty string when the period has no wind group — a
  /// TEMPO that only changes visibility, say — and that throws. Same for the
  /// groups behind `flightCategory`.
  List<ForecastSummary>? get forecastSummaries {
    final forecasts = _tolerantly(() => rawObject.forecasts);
    if (forecasts == null) return null;
    return forecasts.map((forecast) {
      final wind = _tolerantly(() => forecast.wind);
      return ForecastSummary(
        from: forecast.fcstTimeFrom.toUtc(),
        to: forecast.fcstTimeTo.toUtc(),
        category:
            _tolerantly(() => forecast.flightCategory) ?? FlightCategory.NONE,
        windDirectionDeg: wind?.direction,
        windSpeedKt: wind?.speed.toDouble(),
        // `gust` stays nullable even where `isGusty` is set, so a gust group
        // that could not be read degrades to a plain wind.
        windGustKt: wind != null && wind.isGusty ? wind.gust?.toDouble() : null,
        qualifier:
            qualifierText(forecast.changeIndicator.name, forecast.probability),
      );
    }).toList(growable: false);
  }
}

/// Qualifier of a TAF period, e.g. `TEMPO`, `PROB30`, `PROB30 TEMPO`.
///
/// The parser reports `probability` as 100 for a period with no PROB group at
/// all, so only a value below that is a probability worth printing. The base
/// period of the report qualifies nothing and stays blank.
String qualifierText(String indicator, int probability) {
  final parts = <String>[
    if (indicator != 'TAF') indicator,
    if (probability > 0 && probability < 100) '$probability%',
  ];
  return parts.join(' ');
}

/// Reads [value], yielding null when the parser throws rather than reporting
/// an absent group.
T? _tolerantly<T>(T Function() value) {
  try {
    return value();
  } catch (_) {
    return null;
  }
}
