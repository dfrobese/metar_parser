import 'dart:collection';
import 'package:metar_parser_dart/src/cloud_coverage.dart';
import 'package:metar_parser_dart/src/cloud_layer.dart';
import 'package:xml/xml.dart';


/// Stack of clouds
class CloudList<T extends CloudLayer> extends ListBase<T> {
  List innerList = List.generate(0, (index) => null);

  int get length => innerList.length;

  void set length(int length) {
    innerList.length = length;
  }

  void operator []=(int index, T value) {
    innerList[index] = value;
  }

  T operator [](int index) => innerList[index];

  // Though not strictly necessary, for performance reasons
  // you should implement add and addAll.

  void add(T value) => innerList.add(value);

  void addAll(Iterable<T> all) => innerList.addAll(all);

  CloudList();
}


class CloudStack extends CloudList<CloudLayer> {
  CloudStack();
  /// Create object from string
  static CloudStack? fromElement(XmlElement metarElement) {


    // check for VV
    final vv_condition = metarElement.getElement('vert_vis_ft')?.innerText;
    if (vv_condition != null) {
       final stack = new CloudStack();
       final layer = CloudLayer.from(CloudCoverage.VV, int.parse(vv_condition));
       stack.add(layer);
       return stack;
    }
    // All other are cloud layers
    final sky_condition = metarElement.findElements('sky_condition');
    if (sky_condition.length > 0) {
      final stack = new CloudStack();
      for (var sky in sky_condition) {
        final layer = CloudLayer.fromElement(sky);
        stack.add(layer);
      }
      return stack;
    }
    return null;
  }

  /// Parses a TAF cloud string into a list of CloudLayer objects.
  factory CloudStack.fromRaw(String tafCloudString) {
    var stack = new CloudStack();

    // check special weather acronym
    final RegExp specRegex = RegExp("(${CloudCoverage.regSpecStr})");
    final match = specRegex.firstMatch(tafCloudString);
    if (match != null) {
      final item = CloudCoverage.parse(match[0]!);
       stack.add(CloudLayer.from(item, item.defaultCloudbase));
       return stack;
    }

    // create cloud stack
    final RegExp cloudRegex = RegExp("(${CloudCoverage.regCloudStr})(\\d{3})");
    final matches = cloudRegex.allMatches(tafCloudString);

    matches.forEach((match) {
      final coverageString = match.group(1)!; // Cloud coverage code (e.g., VV, FEW)
      final baseAGL = int.parse(match.group(2)!) * 100; // Base altitude in feet (e.g., 030 -> 3000 ft)

      // Map the coverage string to the corresponding CloudCoverage enum.
      final coverage = CloudCoverage.values.firstWhere(
            (e) => e.toString().split('.').last == coverageString,
        orElse: () => throw ArgumentError('Unknown cloud coverage: $coverageString'),
      );

      stack.add(CloudLayer.from(coverage, baseAGL));
    });
    return stack;
  }

  int? _lowestSignificantCloudBase() {
    if (this.isEmpty) {
       return null;
    }
    var lowestAGL = CloudCoverage.SKC.defaultCloudbase;
    this.forEach((element) {
          if (element.coverage.cloudCover >= CloudCoverage.BKN.cloudCover &&
              element.baseAGL <= lowestAGL) {
            lowestAGL = element.baseAGL;
          }
    });
    return lowestAGL;
  }

  late final int? lowestSignificantCloudBase = this._lowestSignificantCloudBase();
}

