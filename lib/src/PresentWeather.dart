class PresentWeather {

  static final intensity = {"-": "light", "+": "heavy", "VC": "vicinity", "RE": "recent"};
  static final descriptor = {"MI": "shallow", "BC": "patches", "DR": "low drifting", "BL": "blowing", "SH": "showers", "TS": "thunderstorms", "FZ": "freezing", "PR": "partial"};
  static final precipitation = {"DZ": "drizzle", "RA": "rain", "SN": "snow", "SG": "snow grains", "IC": "ice crystals", "PL": "ice pellets", "GR": "hail", "GS": "snow pellets", "UP": "unknown"};
  static final obscuration = {"BR": "mist", "FG": "fog", "FU": "smoke", "DU": "dust", "SA": "sand", "HZ": "haze", "PY": "spray", "VA": "volcanic ash"};
  static final other = {"PO": "dust/sand whirls", "SQ": "squalls", "FC": "🌪 tornado or waterspout", "SS": "sandstorm", "DS": "duststorm"};
  static final symbols= {"DZ": "🌦", "RA": "🌧", "SN": "🌨", "SG": "❄️", "IC": "❄️", "PL": "❄️", "GR": "❄️ hail", "GS": "❄️", "UP": "?", "VA": "🌋", "FC": "🌪",  "TS": "🌩", "FZ": "❄️", "BR": " 💨"};

  static final intensityRegStr = {"-", "\\+", "VC", "RE"}.join("|");
  static final descriptorRegStr = "(" + PresentWeather.descriptor.keys.join("|") + ")" ;
  static final precipitationRegStr = "(" + PresentWeather.precipitation.keys.join("|") + ")";
  static final obscurationRegStr = "(" + PresentWeather.obscuration.keys.join("|") + ")";
  static final otherReStr = "(" + PresentWeather.other.keys.join("|") + ")";

  String wxString;
  String text;
  String symbol;

  PresentWeather._(this.wxString, this.text, this.symbol);

  factory PresentWeather.parse(String line) {
    StringBuffer text = StringBuffer();
    StringBuffer symbol = StringBuffer();
    var rx = RegExp(intensityRegStr);
    var matches = rx.allMatches(line);
    matches.forEach((element) => text.write((intensity[element[0]] ?? "") + " "));
    rx = RegExp(descriptorRegStr);
    matches = rx.allMatches(line);
    matches.forEach((element) => text.write((descriptor[element[0]] ?? "") + " "));
    rx = RegExp(precipitationRegStr);
    matches = rx.allMatches(line);
    matches.forEach((element) {
      var found = element[0];
      text.write((precipitation[found] ?? "") + " ");
      symbol.write(symbols[found] ?? "");
    });
    rx = RegExp(obscurationRegStr);
    matches = rx.allMatches(line);
    matches.forEach((element) {
      var found = element[0];
      text.write((obscuration[found] ?? "") + " ");
      symbol.write(symbols[found] ?? "");
    });
    rx = RegExp(otherReStr);
    matches = rx.allMatches(line);
    matches.forEach((element) {
      var found = element[0];
      text.write((other[found] ?? "") + " ");
      symbol.write(symbols[found] ?? "");
    });

    return PresentWeather._(line, text.toString().trim(), symbol.toString());
   }
}