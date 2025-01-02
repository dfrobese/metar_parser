
import 'package:metar_parser_dart/src/CloudCoverage.dart';
import 'package:xml/xml.dart';


/// sky_condition	sky_cover - up to four levels of sky cover and base can be reported under the sky_conditions field;
/// OVX present when vert_vis_ft is reported.
/// Allowed values: SKC|CLR|CAVOK|FEW|SCT|BKN|OVC|OVX	string
/// cloud_base_ft_agl - height of cloud base in feet AGL. Up to four levels can be reported under the sky_conditions field.
/// A value exists when the corresponding sky_cover='FEW','SCT','BKN', 'OVC'	integer	ft (AGL)

class CloudLayer {


  CloudLayer._(this.coverage, this.baseAGL);

  /// Create object from XML attributes
  factory CloudLayer.fromElement(XmlElement cloudElement) {
    var layer = CloudLayer._(CloudCoverage.CAVOK, CloudCoverage.CAVOK.defaultCloudbase);
    for (var attribute in cloudElement.attributes) {
      if (attribute.name.toString() == "sky_cover") {
        layer.coverage = CloudCoverage.parse(attribute.value);
        layer.baseAGL = layer.coverage.defaultCloudbase;
      }
      if (attribute.name.toString() == "cloud_base_ft_agl") {
        layer.baseAGL = int.parse(attribute.value);
      }
    }
    return layer;
  }

  /// create cloud layer from coverage and base in feet AGL
  factory CloudLayer.from(CloudCoverage cover,  int base) {
      return CloudLayer._(cover, base);
  }



  CloudCoverage coverage;
  /// Base AGL inb feet
  int baseAGL;
}
