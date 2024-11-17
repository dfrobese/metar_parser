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


}
