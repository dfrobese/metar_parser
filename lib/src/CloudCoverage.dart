/// CLoud layer description
///
///
enum CloudCoverage {
  SKC, CLR, NSC, FEW, SCT, BKN, OVC, VV, OVX, CAVOK, NCD;

  static final List<CloudAppearance> _defaultAppearances = [
    CloudAppearance(25000.0, 0.0, '☀️'),  // SKC
    CloudAppearance(12000.0, 0.0, '☀️'),  // CLR
    CloudAppearance(5000.0, 0.0, '☀️'),   // NSC
    CloudAppearance(0.0, 1 / 8, '🌤️'),    // FEW
    CloudAppearance(0.0, 3 / 8, '⛅️'),    // SCT
    CloudAppearance(0.0, 5 / 8, '🌥'),     // BKN
    CloudAppearance(0.0, 1.0, '☁️'),      // OVC
    CloudAppearance(0.0, 1.0, ''),        // VV
    CloudAppearance(0.0, 1.0, ''),        // OVX
    CloudAppearance(5000.0, 0.0, '☀️'),   // CAVOK
    CloudAppearance(5000.0, 0.0, '☀️'),   // NCD
  ];


  // Cloud Reg
  static final regStr = CloudCoverage.values.map((e){return e.name;}).join("|");

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
  double get defaultCloudbase {
    assert(this.index <= CloudCoverage._defaultAppearances.length);
    return CloudCoverage._defaultAppearances[this.index].cloudCover;
  }

  /// get associated weather symbol
  String get symbol {
    assert(this.index <= CloudCoverage._defaultAppearances.length);
    return CloudCoverage._defaultAppearances[this.index].symbol;
  }
}

class CloudAppearance {
  /// default cloudbase
  final double defaultCloudbase ;
  /// cloud cover
  final  double cloudCover ;
  /// weather symbol
  final String symbol;

  CloudAppearance(this.defaultCloudbase, this.cloudCover, this.symbol);
}