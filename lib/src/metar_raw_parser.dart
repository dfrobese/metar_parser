
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
        return r'\s(\d{3})V(\d{3})';
      case windVRB:
        return 'VRB(\\d{2})(${WindUnit.regStr})';
      case wind:
        return '(\\d{3})(\\d{2})(G\\d{2})?(${WindUnit.regStr})?';
      case rvr:
        return "(R\\d{2}(\\w)?/([A-Z])?\\d{4}(V\\d{4})?(${RVRTrend.regStr})\\s)+";
      case visibility:
        return r'(CAVOK|\d{4}|(?:P?\d{1,2}SM))';
      case weather:
        return "((?:\\+|-|\\s|VC|RE)?(${PresentWeather.descriptorRegStr})?(${PresentWeather.precipitationRegStr}){1,2}|(${PresentWeather.obscurationRegStr}|${PresentWeather.otherReStr}))+";
      case clouds:
        return "(((${CloudCoverage.regStr})\\d{3})(CB|TCU)?\\s)+";
      case temperature:
        return r'(M?\d{2})\/(M?\d{2})';
      case altimeter:
        return r'((?:Q|A)\d{4})';
      case change:
        return "(NOSIG|((BECMG|TEMPO)\\s+\\d{4}(?:\\s[+-]?[A-Z]{2,4})?\\s?(?:${CloudCoverage.regStr})\\d{3}))";
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
  String remaining = metar;


    for (var element in MetarRawElement.values) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null) {
        parsedMetar[element.name] = match.group(0)?.trim();
        remaining = remaining.substring(match.end).trim();
      }
    }
    // Exit if no match is found in current remaining string
    return parsedMetar;
  }
}
