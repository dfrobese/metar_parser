
import 'package:metar_parser_dart/src/PresentWeather.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:metar_parser_dart/src/rvr.dart';
import '../CloudCoverage.dart';

enum MetarRawElement {
  typeMetar,
  typeTaf,
  station,
  published,
  endurance,
  mode,
  wind,
  windVRB,
  windVaries,
  visibility,
  rvr,
  weather,
  clouds,
  temperature,
  altimeter,
  changeMetar,
  change_indicator,
  remark,
  icingGroup,
  turbulenceGroup;

  // Method to generate dynamic regex pattern for each element
  String get regExpString {
    switch (this) {
      case typeMetar:
        return r'(METAR|SPECI)?';
      case typeTaf:
        return r'(TAF)';
      case station:
        return r'([A-Z0-9]{4})\s+';
      case published:
        return r'(?:(\d{2}\d{2}\d{2}Z))\s+';
      case endurance:
        return r'(\d{2}\d{2})\/(\d{2}\d{2})\s+';
      case mode:
        return r'(COR|AUTO|NIL|CNL|AMD)\s+';
      case windVaries:
        return r'(\d{3})V(\d{3})';
      case windVRB:
        return 'VRB(\\d{2})(${WindUnit.regStr})';
      case wind:
        return '(\\d{3})(\\d{2})(G\\d{2})?(${WindUnit.regStr})?';
      case visibility:
        return r'(?:(P?\d{1,2}|((\d\s)?\d\/\d))SM)|(?:(\d{4}([NSWE]{1,2})?)(\s\d{4}([NSWE]{1,2})?)?)';
      case rvr:
        return "(R\\d{2}(\\w)?\\/([A-Z])?\\d{4}(V\\d{4})?(${RVRTrend.regStr})\\s)+";
      case weather:
        return "(?:((\\+|-|\\s|VC|RE)?(${PresentWeather.descriptorRegStr})?(${PresentWeather.precipitationRegStr}){1,2}|(${PresentWeather.obscurationRegStr}|${PresentWeather.otherReStr}))\\s)+";
      case clouds:
        return "((${CloudCoverage.regSpecStr})|(((${CloudCoverage.regCloudStr})(\\d{3}|\\/{3})(CB|TCU)?\\s)+))";
      case temperature:
        return r'(M?\d{2})\/(M?\d{2})';
      case altimeter:
        return r'((?:QNH|Q|A)\d{4})(INS|HPA)?';
      case changeMetar:
        return "(NOSIG|((BECMG|TEMPO)\\s(?:${MetarRawElement.wind.regExpString}\\s?)?(?:${MetarRawElement.visibility.regExpString}\\s?)?(?:${MetarRawElement.weather.regExpString})?(?:${MetarRawElement.clouds.regExpString})?))";
      case change_indicator:
        return r'((PROB\d{2}|BECMG|TEMPO|FM\d{6})|(PROB\d{2}\sTEMPO))';
      case remark:
        return r'(RMK.+)';
      case icingGroup:
        return r'(6\d{5})';
      case turbulenceGroup:
        return r'(5\d{5})';
        break;
    }
    return "";
  }
  static const metarSequence = [typeMetar, station, published, mode, wind, windVRB, windVaries, visibility,
    rvr, weather, clouds, temperature, altimeter, changeMetar, remark];
  static const tafStartSequence = [typeTaf, mode,station, published, endurance, wind, windVRB, windVaries, visibility, weather, clouds, temperature, altimeter];
  static const tafChangeSequence = [change_indicator, endurance, wind, windVRB, windVaries, visibility, weather, clouds, temperature, altimeter];
  static const tafEndSequence = [mode, remark];
}


class MetarTafRawParser {
static Map<String, String?> parseMetarRawText(String metar) {
  Map<String, String?> parsedMetar = {};
  String remaining = metar+"\n"; // Add CR als end marker


    for (var element in MetarRawElement.metarSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0) {
        parsedMetar[element.name] = match.group(0)?.trim();
        remaining = remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    // Exit if no match is found in current remaining string
    return parsedMetar;
  }

static List<Map<String, String?>> parseTafRawText(String taf) {

  String remaining = taf+"\n"; // Add CR als end marker
  List<Map<String, String?>> result = [];

  // start sequence
  Map<String, String?> parsedTafStart = {};
  for (var element in MetarRawElement.tafStartSequence) {
    final match = RegExp(element.regExpString).firstMatch(remaining);
    if (match != null && match.start == 0) {
      parsedTafStart[element.name] = match.group(0)?.trim();
      remaining = remaining.substring(match.end).trimLeft(); // keep end marker
    }
  }
  result.add(parsedTafStart);

  // change sequence loop
  while (RegExp(MetarRawElement.change_indicator.regExpString).firstMatch(remaining) != null) {
    // change sequence
    Map<String, String?> parsedTafChange = {};
    for (var element in MetarRawElement.tafChangeSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0) {
        parsedTafChange[element.name] = match.group(0)?.trim();
        remaining =
            remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    result.add(parsedTafChange);
  }
  // End sequence
  Map<String, String?> parsedTafEnd = {};
  for (var element in MetarRawElement.tafEndSequence) {
    final match = RegExp(element.regExpString).firstMatch(remaining);
    if (match != null && match.start == 0) {
      parsedTafEnd[element.name] = match.group(0)?.trim();
      remaining = remaining.substring(match.end).trimLeft(); // keep end marker
    }
  }
  result.add(parsedTafEnd);

  // Exit if no match is found in current remaining string
  return result;
}
}
