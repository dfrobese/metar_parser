import 'dart:math' as math;

import 'package:metar_parser_dart/src/tds_parser/metar_tds.dart';
import 'package:metar_parser_dart/src/wind.dart';

/// Wind split into its components along and across a runway.
class WindComponent {
  /// Knots along the runway; positive is a headwind, negative a tailwind.
  final int headwind;

  /// Knots across the runway; positive from the right, negative from the left.
  final int crosswind;

  const WindComponent({required this.headwind, required this.crosswind});

  /// Components of [wind] relative to a runway heading of [rwyHeading] degrees.
  ///
  /// Wind direction and runway heading must refer to the same north (both
  /// true or both magnetic), otherwise the split is off by the variation.
  factory WindComponent.forRunway(Wind wind, num rwyHeading) {
    final windRad = (wind.direction - rwyHeading) * math.pi / 180.0;
    return WindComponent(
      headwind: (wind.speed * math.cos(windRad)).round(),
      crosswind: (wind.speed * math.sin(windRad)).round(),
    );
  }
}

/// Runway wind components straight from a METAR.
extension MetarWindComponent on MetarTDS {
  /// Headwind and crosswind of the reported wind for [rwyHeading] degrees.
  WindComponent windComponentForRunway(num rwyHeading) =>
      WindComponent.forRunway(wind, rwyHeading);
}
