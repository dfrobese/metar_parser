/// CLoud layer description
///
enum CloudCoverage {
  SKC, CLR, NSC, FEW, SCT, BKN, OVC, VV, OVX, CAVOK;

  /// default cloudbase
  static final List<double> defaultCloudbases = [25000.0, 12000, 5000, 0, 0, 0, 0, 0, 0, 5000];

  /// cloud cover
  static final List<double> cloudCovers = [0.0, 0, 0, 1/8, 3/8, 5/8, 1, 1, 1, 0];

  /// weather symbol
  static final symbols = ['☀️', '☀️', '☀️', '🌤️', '⛅️', '🌥', '☁️', '', '', '☀️'];

  /// Create object from string
  factory CloudCoverage.parse(String str) {
    var cl = CloudCoverage.values.firstWhere((e) => e.name == str.toUpperCase());
    return cl;
  }

  /// get cloud cover
  double get cloudCover {
    assert(this.index <= CloudCoverage.cloudCovers.length);
    return CloudCoverage.cloudCovers[this.index];
  }

  /// get default cloudbase
  double get defaultCloudbase {
    assert(this.index <= CloudCoverage.defaultCloudbases.length);
    return CloudCoverage.defaultCloudbases[this.index];
  }

  /// get associated weather symbol
  String get symbol {
    assert(this.index <= CloudCoverage.symbols.length);
    return CloudCoverage.symbols[this.index];
  }
}