import 'package:MetarParser/src/PresentWeather.dart';
import 'package:test/test.dart';

void main () {
  test('Present Weather test', () {
    var weather = PresentWeather.parse("RERA");
    expect(weather.text.toString(), 'recent rain');
    weather = PresentWeather.parse("RETSGR");
    expect(weather.text.toString(), 'recent thunderstorm hail');

    print(weather.text);
  });
}