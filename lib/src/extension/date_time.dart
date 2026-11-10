import "package:intl/intl.dart";



extension DateTimeExtension on DateTime {

  /// create Metar timesting hhmmz
  String toTimeString() {
    final f = NumberFormat("00");
    return "${f.format(hour)}:${f.format(minute)}${isUtc ? "z" : ""}";
  }

  /// parse issue time of Taf format is "ddhhmmZ" month and
  /// year will be set to current date
  ///
  /// A TAF without issue time and validity ("TAF EDXX NIL", cancelled TAFs)
  /// has no such group; then the current time stands in instead of failing.
  static DateTime parseIssueTime(String issueTimeString) {
    final now = DateTime.now().toUtc();
    final match = RegExp(r'^(\d{2})(\d{2})(\d{2})').firstMatch(issueTimeString.trim());
    if (match == null) return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
    final day = int.parse(match.group(1)!);
    final hour = int.parse(match.group(2)!);
    final minute = int.parse(match.group(3)!);
    return DateTime.utc(now.year, now.month, day, hour, minute);
  }

  /// parse valid date from/to string, assuming the format is ""ddhh/ddhh"
  static List<DateTime> parseValidTimes(String endurance) {
    // Assuming the format is "ddhh/ddhh"
    final now = DateTime.now().toUtc();

    final fromDay = int.parse(endurance.substring(0, 2));
    final fromHour = int.parse(endurance.substring(2, 4));
    final toDay = int.parse(endurance.substring(5, 7));
    final toHour = int.parse(endurance.substring(7, 9));
    final validTimeFrom = DateTime.utc(now.year, now.month, fromDay, fromHour);
    final validTimeTo = DateTime.utc(now.year, now.month, toDay, toHour);
    return [validTimeFrom, validTimeTo];
  }

}