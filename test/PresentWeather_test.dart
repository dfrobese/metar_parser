import 'package:metar_parser_dart/src/PresentWeather.dart';
import 'package:test/test.dart';

void main () {
   test('Present Weather test', () {
    var weather = PresentWeather.parse("RERA");
    expect(weather.text.toString(), 'recent rain');
    print(weather.text);
    weather = PresentWeather.parse("RETSGR");
    expect(weather.text.toString(), 'recent thunderstorms hail');
    print(weather.text);
    weather = PresentWeather.parse("-FZRA");
    expect(weather.text.toString(), 'light freezing rain');
    print(weather.text);
    weather = PresentWeather.parse("+SHRA");
    expect(weather.text.toString(), 'heavy showers rain');
    print(weather.text);
    weather = PresentWeather.parse("-SN BR");
    expect(weather.text.toString(), 'light snow mist');
    print(weather.text);
  });


}