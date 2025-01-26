// Weight enumeration with corresponding descriptions

enum RVRWeight {
  Less("<=", "⋜"),
  More(">=", "≥"),
  Void("", "");

  final String rawValue;
  final String symbol;

  const RVRWeight(this.rawValue, this.symbol);

  String get description => symbol;
}

/// Trend enumeration with corresponding descriptions
enum RVRTrend {
  Upward,
  Downward,
  NoChange;

  factory RVRTrend.parse(String str) {

    if (str.length == 0  || str.length > 1) {
      return RVRTrend.NoChange;
    }
    var fc = RVRTrend.values.firstWhere((e) => e.name.startsWith(str.toString()));
    return fc;
  }
}

/// Describes Runway Visual Range (RVR)
///
class RVR {

  final String runway;
  final String? lowVisibility;
  final String? highVisibility;
  final RVRTrend? trend;

  RVR._(this.runway, this.lowVisibility, this.highVisibility, this.trend);


  static List<RVR?>? parseRVR(String? rvrString) {
    if (rvrString == null) {
      return null;
    }
    // Regexp
    // r'(R[0-9]{2}[LRC]?((\/P?[0-9]{4}(?:V(P?)[0-9]{4})?(?:FT)?(?:\/?[UDN])?)|\/{5})\s)+'
    final rvrRegex = RegExp(
        r'R(?<runway>[0-9]{2}[LRC]?)\/'
        r'P?(?<lowVisibility>[0-9]{4})'
        r'(?:V(P?)(?<highVisibility>[0-9]{4}))?'
        r'(?:FT)?'
        r'(?:/(?<trend>[UDN]))?'
    );

    return rvrString.trim().split(" ").map((rvrStr) {
      final match = rvrRegex.firstMatch(rvrStr);
      if (match == null) {
        return null;
      }

      final runway = match.namedGroup('runway');
      if (runway == null) {
        return null;
      }
      final lowVisibility = match.namedGroup('lowVisibility');
      final highVisibility = match.namedGroup('highVisibility');
      final String trend = (match.namedGroup('trend')?[0] ?? 'N');

      return RVR._(runway, lowVisibility, highVisibility, RVRTrend.parse(trend));
    }).toList();
  }
}
