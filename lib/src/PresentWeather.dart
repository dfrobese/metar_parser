

class PresentWeather {

  static final intensity = {"-": "light", "+": "heavy", "VC": "vicinity", "RE": "recent"};
  static final descriptor = {"MI": "shallow", "BC": "patches", "DR": "low drifting", "BL": "blowing", "SH": "showers", "TS": "thunderstorms", "FZ": "freezing", "PR": "partial"};
  static final precipitation = {"DZ": "drizzle", "RA": "rain", "SN": "snow", "SG": "snow grains", "IC": "ice crystals", "PL": "ice pellets", "GR": "hail", "GS": "snow pellets", "UP": "unknown"};
  static final obscuration = {"BR": "mist", "FG": "fog", "FU": "smoke", "DU": "dust", "SA": "sand", "HZ": "haze", "PY": "spray", "VA": "volcanic ash"};
  static final other = {"PO": "dust/sand whirls", "SQ": "squalls", "FC": "🌪 tornado or waterspout", "SS": "sandstorm", "DS": "duststorm"};
  static final symbols= {"DZ": "🌦", "RA": "🌧", "SN": "🌨", "SG": "❄️", "IC": "❄️", "PL": "❄️", "GR": "❄️ hail", "GS": "❄️", "UP": "?", "VA": "🌋", "FC": "🌪",  "TS": "🌩", "FZ": "❄️", "BR": " 💨"};


  static final String intensityRegStr = {"-", "\\+", "VC", "RE"}.join("|");
  static final String descriptorRegStr =  PresentWeather.descriptor.keys.join("|") ;
  static final String precipitationRegStr =  PresentWeather.precipitation.keys.join("|") ;
  static final String obscurationRegStr =  PresentWeather.obscuration.keys.join("|");
  static final String otherReStr = PresentWeather.other.keys.join("|");

  static final pattern = [[intensityRegStr, intensity], [descriptorRegStr, descriptor], [precipitationRegStr, precipitation], [obscurationRegStr, obscuration], [otherReStr, other]];

  /// weather string coded
  String wxString;
  /// weather decoded
  String text;
  /// symbols
  String symbol;

  PresentWeather._(this.wxString, this.text, this.symbol);

  factory PresentWeather.parse(String wxString) {

    var line = wxString;
    StringBuffer text = StringBuffer();
    StringBuffer symbol = StringBuffer();

    pattern.forEach((pair) {
      // regex string
      var rx = RegExp(pair[0] as String);
      var matches = rx.allMatches(line);
      matches.forEach((element) {
        var found = element[0];
        line = line.substring(element.end);
        // map found acronym to plain text
        text.write(((pair[1] as Map<String, String>)[found] ?? "") + " ");
        symbol.write(symbols[found] ?? "");
      });
    });

    return PresentWeather._(line, text.toString().trim(), symbol.toString());
   }


   String toString() {

    return text;

   }
}