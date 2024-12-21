
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
  windGusts,
  windVaries,
  windChange,
  windsGrid,
  visibility,
  rvr,
  weatherTaf,
  weather,
  clouds,
  cloudsChange,
  windSheer,
  icingTurboGroup,
  temperature,
  altimeter,
  temperatureChange,
  frictionState,
  changeMetar,
  change_indicator,
  remark,
  correctionAt;

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
        return r'(?:(\d{2}\d{2}\d{2}Z?))\s+';
      case endurance:
        return r'(\d{2}\d{2})\/(\d{2}\d{2})\s+';
      case mode:
        return r'(COR|AUTO|NIL|CNL|AMD)';
      case windVaries:
        return r'(\d{3})V(\d{3})';
      case windGusts: // directional wind with gusts
        return "((\\d{3})|VRB)(\\d{1,3})(G\\d{2})?(${WindUnit.regStr})";
      case windChange: // Taf wind change
        return "((WND\\s)?(${MetarRawElement.windGusts.regExpString}|${MetarRawElement.windVaries.regExpString})(\\sAFT\\s\\d{4}\\s)?(ROTOR\\sCONDS\\sEXIST)?)";
      case windsGrid:
        return r'(ALL\sWINDS\sGRID)';
      case visibility: // horizontal visibility
        return r'(?:(P?\d{1,2}|((\d\s)?\d\/\d))SM)|(?:(\d{3,4}\s){1,2})';
      case rvr:  // runway visbility range
        return "(R\\d{2}(\\w)?\\/([A-Z])?\\d{4}(V\\d{4})?(${RVRTrend.regStr})\\s)+";
      case weather: // possible weather coding
        return "(?:((\\+|-|\\s|VC|RE)?(${PresentWeather.descriptorRegStr})?((${PresentWeather.precipitationRegStr}){1,3}|(${PresentWeather.obscurationRegStr})|(${PresentWeather.otherReStr}))?)\\s)+";
      case weatherTaf: // TAF wx is NSW possible
        return "(NSW|(${weather.regExpString}))";
      case clouds: // cloud coverage
        return "((${CloudCoverage.regSpecStr})|(((${CloudCoverage.regCloudStr})(\\d{3}|\\/{3})(CB|TCU)?\\s)+))";
      case cloudsChange: // cloud coverage TAF on change
        return "((${MetarRawElement.clouds.regExpString})(AFT\\s\\d{4}))";
      case windSheer: // wind sheer
        return r'(WS((\d{3}\/\d{5}KT)|CONDS))';
      case icingTurboGroup: // TAF icing and turbolence items, starts with 5 or 6, can be multiple
        return r'(([56]\d{5}\s)+)';
      case temperature: // METAR temperature
        return r'(M?\d{2})\/(M?\d{2})';
      case altimeter: // Altimeter
        return r'((?:QNH|Q|A)\d{4})(INS|HPA)?';
      case temperatureChange:   // TAF temperature change T, TX, TN
        return r'(((T(X|N)?(M?\d{2})\/\d{4}Z)\s)+)';
      case frictionState: // ground friction
        return r'(FS\d{5})';
      case changeMetar: // change block for a Metar at the tail
        return "(NOSIG|((BECMG|TEMPO)\\s(?:${MetarRawElement.windChange.regExpString}\\s?)?(?:${MetarRawElement.visibility.regExpString}\\s?)?(?:${MetarRawElement.weather.regExpString})?(?:${MetarRawElement.clouds.regExpString})?))";
      case change_indicator: // change indicator for next group
        return r'((PROB\d{2}|BECMG|TEMPO|INTER|FM\d{6})|(PROB\d{2}\sTEMPO))';
      case remark: // remark section
        return r'((RMK)?.+)';
      case correctionAt: // TAF correction time
        return r'((COR|AMD)\s\d{4})';
        break;
    }
    return "";
  }
  static const metarSequence = [typeMetar, station, published, mode, windGusts, windVaries, visibility,
    rvr, weather, clouds, temperature, altimeter, changeMetar, remark];
  static const tafSequence = [windGusts, windVaries, windSheer, visibility, weatherTaf, clouds, icingTurboGroup, altimeter, temperatureChange, cloudsChange, windChange, windsGrid];
  static const tafStartSequence = [typeTaf, mode,station, published, endurance, ...tafSequence];
  static const tafChangeSequence = [change_indicator, endurance, ...tafSequence];
  static const tafEndSequence = [correctionAt, frictionState, remark];
}


class MetarTafRawParser {

  /// Parese a raw Metar text and give back a map of items found
  static Map<String, String?> parseMetarRawText(String metar) {
    Map<String, String?> parsedMetar = {};
    String remaining = metar + "\n"; // Add CR als end marker


    for (var element in MetarRawElement.metarSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0) {
        parsedMetar[element.name] = match.group(0)?.trim();
        remaining =
            remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    // Exit if no match is found in current remaining string
    return parsedMetar;
  }

  /// split a raw Taf string in segments
  static List<String> segmentTaf(String taf) {
    // Define the regex to identify TAF change indicators
    final regex = RegExp(MetarRawElement.change_indicator.regExpString);

    // Split the TAF into parts based on the regex
    final parts = taf.split(regex);

    // Filter out empty or whitespace-only parts
    return parts.where((part) =>
    part
        .trim()
        .isNotEmpty).toList();
  }

  /// static parse Taf start segment
  static Map<String, String?> parseTafRaStartSegment(String taf) {
    var remaining = taf;
// start sequence
    Map<String, String?> parsedTafStart = {};
// loop over start sequence
    for (var element in MetarRawElement.tafStartSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null) {
// on match, store item and remove from input string (remaining string)
        parsedTafStart[element.name] = match.group(0)?.trim();
        remaining =
            remaining.replaceRange(
                match.start, match.end, ""); // keep end marker
      }
    }
    return parsedTafStart;
  }


/// static parse Taf change segments
static List<Map<String, String?>> parseTafRawChangeSegments(String taf) {
  List<Map<String, String?>> result = [];
  var remaining = taf;
// change sequence
  Map<String, String?> parsedTafChange = {};
  // loop over the sequence
  for (var element in MetarRawElement.tafChangeSequence) {
    final match = RegExp(element.regExpString).firstMatch(remaining);
    if (match != null) {
      parsedTafChange[element.name] = match.group(0)?.trim();
      remaining =
          remaining.replaceRange(match.start, match.end, "");
    }
  }
  if (parsedTafChange.length > 0) { // if change group found, add it
    result.add(parsedTafChange);
  }
  return result;
}



static List<Map<String, String?>> parseTafRawText(String taf) {

  var segments = segmentTaf(taf+"\n");






  result.add(parsedTafStart);

  // change sequence loop. Look for change indicator to beginn
  var matchIndicator;
  while ((matchIndicator = RegExp(MetarRawElement.change_indicator.regExpString).firstMatch(remaining)) != null) {
    remaining = remaining.substring(matchIndicator.start).trimLeft();

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
