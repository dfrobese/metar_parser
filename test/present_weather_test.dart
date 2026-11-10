import 'package:metar_parser_dart/src/extension/date_time.dart';
import 'package:metar_parser_dart/src/present_weather.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';


void main () {
 test('Present weather test', () async {
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

  test('several groups, unknown codes and odd spacing always end', () {
    expect(PresentWeather.parse('-RADZ BR').text, 'light rain drizzle mist');
    expect(PresentWeather.parse('  +TSRA  FG ').text, 'heavy thunderstorms rain fog');
    expect(PresentWeather.parse('NSW').text, 'NSW');
    expect(PresentWeather.parse('-RAXX BR').text, 'light rain XX mist');
    expect(PresentWeather.parse('').text, '');
    expect(PresentWeather.parse('-RADZ BR').symbol, contains('🌧'));
  });



  test('a TAF issue time that is no ddhhmm group does not throw', () {
    final now = DateTime.now().toUtc();
    expect(DateTimeExtension.parseIssueTime('101700Z'), DateTime.utc(now.year, now.month, 10, 17));
    expect(DateTimeExtension.parseIssueTime(' 00').year, now.year);
    expect(DateTimeExtension.parseIssueTime('').year, now.year);
  });
}
