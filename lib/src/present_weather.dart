

class PresentWeather {

  static final intensity = {"-": "light", "+": "heavy", "VC": "vicinity", "RE": "recent"};
  static final descriptor = {"MI": "shallow", "BC": "patches", "DR": "low drifting", "BL": "blowing",  "FZ": "freezing", "PR": "partial"};
  static final precipitation = {"SH": "showers", "TS": "thunderstorms","DZ": "drizzle", "RA": "rain", "SN": "snow", "SG": "snow grains", "IC": "ice crystals", "PL": "ice pellets", "GR": "hail", "GS": "snow pellets", "UP": "unknown"};
  static final obscuration = {"BR": "mist", "FG": "fog", "FU": "smoke", "DU": "dust", "SA": "sand", "HZ": "haze", "PY": "spray", "VA": "volcanic ash"};
  static final other = {"PO": "dust/sand whirls", "SQ": "squalls", "FC": "🌪 tornado or waterspout", "SS": "sandstorm", "DS": "duststorm"};
  static final symbols= {"DZ": "🌦", "RA": "🌧", "SN": "🌨", "SG": "❄️", "IC": "❄️", "PL": "❄️", "GR": "❄️ hail", "GS": "❄️", "UP": "?", "VA": "🌋", "FC": "🌪",  "TS": "🌩", "FZ": "❄️", "BR": " 💨"};



  static final String intensityRegStr = {"-", "\\+", "VC", "RE"}.join("|");
  static final String descriptorRegStr =  PresentWeather.descriptor.keys.join("|") ;
  static final String precipitationRegStr =  PresentWeather.precipitation.keys.join("|") ;
  static final String obscurationRegStr =  PresentWeather.obscuration.keys.join("|");
  static final String otherReStr = PresentWeather.other.keys.join("|");

  static final pattern = [intensityRegStr, descriptorRegStr, precipitationRegStr, obscurationRegStr, otherReStr].join("|");
  static final all = {...intensity, ...descriptor,  ...precipitation, ...obscuration , ...other};

  // static final pattern = [[intensityRegStr, intensity], [descriptorRegStr, descriptor], [precipitationRegStr, precipitation], [obscurationRegStr, obscuration], [otherReStr, other]];

  /// weather string coded
  String wxString;
  /// weather decoded
  String text;
  /// symbols
  String symbol;

  PresentWeather._(this.wxString, this.text, this.symbol);

  /// parse weather from single wx string
  factory PresentWeather.parse(String wxString) {

    final text = StringBuffer();
    final symbol = StringBuffer();
    final rx = RegExp(PresentWeather.pattern);

    // Group by group ("-RADZ BR" → "-RADZ", "BR"); within a group the codes
    // follow each other without separator. A remainder no code matches
    // (e.g. "NSW") is kept as it is. Every step consumes input, so the loop
    // always ends (it used to spin forever on the space between groups).
    for (final group in wxString.trim().split(RegExp(r'\s+'))) {
      var rest = group;
      while (rest.isNotEmpty) {
        final match = rx.matchAsPrefix(rest);
        if (match == null || match.end == 0) {
          text.write('$rest ');
          break;
        }
        final item = match[0]!;
        text.write('${all[item] ?? item} ');
        symbol.write(symbols[item] ?? '');
        rest = rest.substring(match.end);
      }
    }
    return PresentWeather._(wxString, text.toString().trim(), symbol.toString());
   }


   String toString() {
    return text;

   }
}