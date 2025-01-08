import 'package:metar_parser_dart/src/present_weather.dart';
import 'package:metar_parser_dart/src/wind.dart';
import 'package:metar_parser_dart/src/rvr.dart';
import '../cloud_coverage.dart';
import 'dart:developer' as developer;

import '../units/velocity_unit.dart';

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
        return r'(\d{2}\d{2})\/(\d{2}\d{2})\s';
      case mode:
        return r'(COR|AUTO|NIL|CNL|AMD)';
      case windVaries:
        return r'(\d{3})V(\d{3})';
      case windGusts: // directional wind with gusts
        return "((\\d{3})|VRB)(\\d{1,3})(G\\d{2})?(${VelocityUnit.regStr})";
      case windChange: // Taf wind change
        return "((WND\\s)?(${MetarRawElement.windGusts.regExpString}|${MetarRawElement.windVaries.regExpString})(\\sAFT\\s\\d{4}\\s)?(ROTOR\\sCONDS\\sEXIST)?)";
      case windsGrid:
        return r'(ALL\sWINDS\sGRID)';
      case visibility: // horizontal visibility
        return r'(?:(P?\d{1,2}|((\d\s)?\d\/\d))SM)|(?:(\d{4}\s){1,2})';
      case rvr: // runway visbility range
        return "(R\\d{2}(\\w)?\\/([A-Z])?\\d{4}(V\\d{4})?(${RVRTrend.regStr})\\s)+";
      case weather: // possible weather coding
        return "(?:((\\+|-|VC|RE)?(${PresentWeather.descriptorRegStr})?(((${PresentWeather.precipitationRegStr})|(${PresentWeather.obscurationRegStr})|(${PresentWeather.otherReStr})){1,3}))\\s)+";
      case weatherTaf: // TAF wx is NSW possible
        return "(NSW|(${weather.regExpString}))";
      case clouds: // cloud coverage
        return "((${CloudCoverage.regSpecStr})|((((${CloudCoverage.regCloudStr})(\\d{3}|\\/{3})(CB|TCU)?)\\s)+))";
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
      case temperatureChange: // TAF temperature change T, TX, TN
        return r'(((T(X|N)?(M?\d{2})\/\d{4}Z)\s)+)';
      case frictionState: // ground friction
        return r'(FS\d{5})';
      case changeMetar: // change block for a Metar at the tail
        return "(NOSIG|((BECMG|TEMPO)\\s(?:${MetarRawElement.windChange.regExpString}\\s?)?(?:${MetarRawElement.visibility.regExpString}\\s?)?(?:${MetarRawElement.weather.regExpString})?(?:${MetarRawElement.clouds.regExpString})?))";
      case change_indicator: // change indicator for next group
        return r'((PROB\d{2}\sTEMPO)|(PROB\d{2}|BECMG|TEMPO|INTER|FM\d{6}))';
      case remark: // remark section/^
        return r'((RMK)?.+)';
      case correctionAt: // TAF correction time
        return r'((COR|AMD)\s\d{4})';
        break;
    }
    return "";
  }

  static const metarSequence = [
    typeMetar,
    station,
    published,
    mode,
    windGusts,
    windVaries,
    visibility,
    rvr,
    weather,
    clouds,
    temperature,
    altimeter,
    changeMetar,
    remark
  ];
  static const tafSequence = [
    windGusts,
    windVaries,
    windSheer,
    visibility,
    weatherTaf,
    clouds,
    icingTurboGroup,
    altimeter,
    temperatureChange,
    cloudsChange,
    windChange,
    windsGrid,
  ];
  static const tafStartSequence = [
    typeTaf,
    mode,
    station,
    published,
    endurance,
    ...tafSequence
  ];
  static const tafChangeSequence = [
    change_indicator,
    endurance,
    ...tafSequence,
    ...tafEndSequence
  ];
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
  static List<String> _segmentTaf(String taf) {
    // Define the regex to identify TAF change indicators
    final regex = RegExp(MetarRawElement.change_indicator.regExpString, multiLine: true);
    final matches = regex.allMatches(taf).toList();
    final result = <String>[];
    var start = 0;
    for (var match in matches) {
      final int end = match.start;
      final String str = taf.substring(start, end-1);
      // Add the text before the match
      result.add(str);
      start = match.start;
    }
    result.add(taf.substring(start, taf.length-1));
    return result;
  }

  /// static parse Taf start segment
  static Map<String, String?> _parseTafRawStartSegment(String taf) {
    var remaining = taf + " "; // Add CR als end marker;
// start sequence
    Map<String, String?> parsedTafStart = {"raw": taf.trim()};
// loop over start sequence
    for (var element in MetarRawElement.tafStartSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0 && match[0] != null ) {
        final item = match[0]!.trim();
        if (item.length > 0) {
          parsedTafStart[element.name] = item;
        }
        remaining = remaining.substring(match.end).trimLeft(); // keep end marker
      }
    }
    remaining = remaining.trim();
    // store unknown part
    if (parsedTafStart.length > 0) {
      developer.log("Taf parsing remains with: $remaining");
      parsedTafStart["remaining"] = remaining;
    }
    return parsedTafStart;
  }

  ///  Parse raw Taf string to decode the given change segment
  static Map<String, String?> _parseTafRawChangeSegment(String taf) {
    var remaining = taf + " "; // Add CR als end marker;
// change sequence
    Map<String, String?> parsedTafChange = {"raw": taf.trim()};
    // loop over the sequence
    for (var element in MetarRawElement.tafChangeSequence) {
      final match = RegExp(element.regExpString).firstMatch(remaining);
      if (match != null && match.start == 0 && match[0] != null ) {
        final item = match[0]!.trim();
        if (item.length > 0) {
          parsedTafChange[element.name] = item;
        }
        remaining = remaining.substring(match.end).trimLeft();
      }
    }
    remaining = remaining.trim();
    if (remaining.length > 0) {
      developer.log("Forecast parsing remains with: $remaining");
      parsedTafChange["remaining"] = remaining;
    }
    return parsedTafChange;
  }

  /// Parse raw Taf string and returns a list of maps with key/value of each forecast part
  static List<Map<String, String?>> parseTafRawText(String taf) {
    List<Map<String, String?>> result = [];
    // Split the whole Taf in segments of each change (forecast)
    var segments = _segmentTaf(taf.startsWith("TAF ") ? "$taf " : "TAF $taf ");
    // parse each segment of change (forecast) found
    for (var segment in segments) {
      if (segment.startsWith("TAF")) {
        result.add(_parseTafRawStartSegment(segment));
      } else {
        result.add(_parseTafRawChangeSegment(segment));
      }
    }
    return result;
  }
}
