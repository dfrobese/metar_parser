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


enum RVRTrend {
  Upward("U", "⬆"),
  Downward("D", "⬇"),
  NoChange("N", "");

  final String rawValue;
  final String symbol;

  const RVRTrend(this.rawValue, this.symbol);

  String get description => symbol;

  static final String regStr =  RVRTrend.values.map((e){return e.rawValue;}).join("|");
}
/// Describes Runway Visual Range (RVR)
///
class RVR {
  // Trend enumeration with corresponding descriptions

  void parseRVR(String rvrString) {
    final rvrRegex = RegExp(
        r'R(?<runway>[0-9]{2}[LRC]?)/'
        r'(?<lowVisibility>[0-9]{4})'
        r'(?:V(?<highVisibility>[0-9]{4}))?'
        r'(?:FT)?'
        r'(?:/(?<trend>[UDN]))?'
    );

    final match = rvrRegex.firstMatch(rvrString);

    if (match != null) {
      final runway = match.namedGroup('runway');
      final lowVisibility = match.namedGroup('lowVisibility');
      final highVisibility = match.namedGroup('highVisibility');
      final trend = match.namedGroup('trend');

      print('Runway: $runway');
      print('Low Visibility: $lowVisibility');
      print('High Visibility: ${highVisibility ?? "N/A"}');
      print('Trend: ${trend ?? "N/A"}');
    } else {
      print('No match found.');
    }
  }


}
