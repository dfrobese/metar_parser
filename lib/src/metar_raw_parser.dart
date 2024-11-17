
import 'package:metar_parser_dart/src/PresentWeather.dart';
import 'package:metar_parser_dart/src/Wind.dart';
import 'package:metar_parser_dart/src/rvr.dart';
import 'CloudCoverage.dart';

enum MetarRawElement {
  type,
  station,
  published,
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
  change,
  remark;

  // Method to generate dynamic regex pattern for each element
  String get regExpString {
    switch (this) {
      case type:
        return r'(METAR|SPECI)?';
      case station:
        return r'([A-Z0-9]{4})\s+';
      case published:
        return r'(\d{2})(\d{2})(\d{2})Z\s+';
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
        return r'((?:Q|A)\d{4})';
      case change:
        return "(NOSIG|((BECMG|TEMPO)\\s(?:${MetarRawElement.wind.regExpString}\\s?)?(?:${MetarRawElement.visibility.regExpString}\\s?)?(?:${MetarRawElement.weather.regExpString})?(?:${MetarRawElement.clouds.regExpString})?))";
      case remark:
        return r'(RMK.+)';

        break;
    }
    return "";
  }
}


class MetarRawParser {
static Map<String, String?> parseMetarRawText(String metar) {
  Map<String, String?> parsedMetar = {};
  String remaining = metar+"\n"; // Add CR als end marker


    for (var element in MetarRawElement.values) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0) {
        parsedMetar[element.name] = match.group(0)?.trim();
        remaining = remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    // Exit if no match is found in current remaining string
    return parsedMetar;
  }
}
