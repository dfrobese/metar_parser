import 'package:metar_parser_dart/src/cloud_layer.dart';
import 'package:metar_parser_dart/src/tds_parser/metar_tds.dart';
import 'package:metar_parser_dart/src/wind.dart';

/// Plain-text renderings of decoded METAR values.
///
/// The TDS reports QNH in inches of mercury and visibility in statute miles;
/// these give the metric form flown by in Europe: QNH in hPa, visibility in
/// metres or kilometres. Cloud bases stay in feet AGL.
extension MetarText on MetarTDS {
  /// QNH in hPa, e.g. `1013 hPa`; `-` when the report carries none.
  String get qnhText => qnhHpaText(altim_in_hg);

  /// Visibility in metres or kilometres, see [metricVisibilityText].
  String get visibilityText => metricVisibilityText(visibility_statute_mi);

  /// The wind group, see [WindText.text].
  String get windText => wind.text;
}

/// Coded form of a wind group.
extension WindText on Wind {
  /// `270/12 kt`, `VRB/03 kt`, `270/12G25 kt`, or `Calm`.
  String get text {
    if (speed == 0) return 'Calm';
    final dir = variable ? 'VRB' : direction.toString().padLeft(3, '0');
    return '$dir/$speed${isGusty ? 'G$gust' : ''} kt';
  }
}

/// Text of one cloud layer.
extension CloudLayerText on CloudLayer {
  /// Coverage and base in feet AGL, e.g. `BKN 1200 ft`; the coverage alone
  /// for the codes that carry no base.
  String get text {
    const withoutBase = {'SKC', 'CLR', 'NSC', 'CAVOK'};
    final cover = coverage.name;
    if (withoutBase.contains(cover)) return cover;
    return '$cover $baseAGL ft';
  }
}

/// QNH given in inches of mercury, as hPa; `-` for a missing (zero) value.
String qnhHpaText(double inHg) {
  if (inHg <= 0) return '-';
  return '${(inHg * 33.8638866667).round()} hPa';
}

/// Visibility given in statute miles, in metric units.
///
/// 9999 m and above reads `over 10 km`, the cap the coded form implies;
/// `-` when no visibility was reported.
String metricVisibilityText(double? statuteMiles) {
  if (statuteMiles == null) return '-';
  final metres = statuteMiles * 1609.344;
  if (metres >= 9999) return 'over 10 km';
  if (metres >= 1000) return '${(metres / 1000).toStringAsFixed(1)} km';
  return '${metres.round()} m';
}
