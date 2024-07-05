import 'dart:collection';
import 'package:metar_parser_dart/src/CloudCoverage.dart';
import 'package:metar_parser_dart/src/CloudLayer.dart';
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
  factory CloudStack.fromElement(XmlElement metarElement) {

    var stack = new CloudStack();
    var sky_condition = metarElement.findElements('sky_condition');
    for (var sky in sky_condition) {
      var layer = CloudLayer.fromElement(sky);
      stack.add(layer);
    }
    return stack;
  }

  double? _lowestSignificantCloudBase() {
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

  late double? lowestSignificantCloudBase = this._lowestSignificantCloudBase();
}

