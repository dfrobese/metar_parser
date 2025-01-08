import 'package:xml/xml.dart';

class Temperature {
  final DateTime validTime;
  final int? maxTempC;
  final int? minTempC;

  Temperature({
    required this.validTime,
    this.maxTempC,
    this.minTempC,
  });

  factory Temperature.fromXml(XmlElement xml) {
    return Temperature(
      validTime: DateTime.parse(xml.getElement('valid_time')?.innerText ?? ''),
      maxTempC: int.tryParse(xml.getElement('max_temp_c')?.innerText ?? ''),
      minTempC: int.tryParse(xml.getElement('min_temp_c')?.innerText ?? ''),
    );
  }
}
