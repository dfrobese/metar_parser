/// CLoud layer description
///
///
enum CloudCoverage {
  VV, // Vertical visibility (obscured sky)
  FEW, // Few clouds (1-2 oktas)
  SCT, // Scattered clouds (3-4 oktas)
  BKN, // Broken clouds (5-7 oktas)
  OVC, // Overcast (8 oktas)
  SKC, // Sky clear
  CLR, // Clear (for automated observations)
  NSC, // No significant clouds
  OVX, // Overcast, indeterminate
  CAVOK, // Ceiling and visibility okay
  NCD; // No clouds detected


  static final List<CloudAppearance> _defaultAppearances = [
    CloudAppearance(0, 1.0, ''),        // VV
    CloudAppearance(0, 1 / 8, '🌤️'),    // FEW
    CloudAppearance(0, 3 / 8, '🌤️'),    // SCT
    CloudAppearance(0, 5 / 8, '⛅️'),     // BKN
    CloudAppearance(0, 1, '☁️'),      // OVC
    CloudAppearance(25000, 0.0, '☀️'),  // SKC
    CloudAppearance(12000, 0.0, '☀️'),  // CLR
    CloudAppearance(5000, 0.0, '☀️'),   // NSC
    CloudAppearance(0, 1.0, ''),        // OVX
    CloudAppearance(5000, 0.0, '☀️'),   // CAVOK
    CloudAppearance(5000, 0.0, '☀️'),   // NCD
  ];


  // Cloud Reg
  static final regCloudStr = CloudCoverage.values.getRange(CloudCoverage.VV.index, CloudCoverage.OVC.index+1).map((e){return e.name;}).join("|");
  static final regSpecStr = CloudCoverage.values.getRange(CloudCoverage.SKC.index, CloudCoverage.values.length).map((e){return e.name;}).join("|");

  /// Create object from string
  factory CloudCoverage.parse(String str) {
    var cl = CloudCoverage.values.firstWhere((e) => e.name == str.toUpperCase());
    return cl;
  }

  /// get cloud cover
  double get cloudCover {
    assert(this.index <= CloudCoverage._defaultAppearances.length);
    return CloudCoverage._defaultAppearances[this.index].cloudCover;
  }

  /// get default cloudbase
  int get defaultCloudbase {
    assert(this.index <= CloudCoverage._defaultAppearances.length);
    return CloudCoverage._defaultAppearances[this.index].defaultCloudbase;
  }

  /// get associated weather symbol
  String get symbol {
    assert(this.index <= CloudCoverage._defaultAppearances.length);
    return CloudCoverage._defaultAppearances[this.index].symbol;
  }

  /// Coverage is special acynym with implicit cloudbases
  bool get isSpecialAcronym => this.index >= CloudCoverage.SKC.index;
}

class CloudAppearance {
  /// default cloudbase
  final int defaultCloudbase ;
  /// cloud cover
  final  double cloudCover ;
  /// weather symbol
  final String symbol;

  CloudAppearance(this.defaultCloudbase, this.cloudCover, this.symbol);
}