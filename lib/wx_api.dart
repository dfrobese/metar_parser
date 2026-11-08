/// Wire model of the VFRInfo weather API (wx/v1) and the decoder that builds
/// it from aviationweather.gov's cache files.
///
/// Used by the wx-service to write JSON and by clients to read it, so both
/// sides share one definition. Plain Dart, no Flutter.
library wx_api;

export 'src/flight_category.dart' show FlightCategory;
export 'src/wx/awc_decoder.dart';
export 'src/wx/wx_models.dart';
