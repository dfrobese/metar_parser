import 'dart:developer' as developer;
import 'package:metar_parser_dart/metar_parser_dart.dart';
import 'package:metar_parser_dart/src/TDSRequest.dart';
import 'package:metar_parser_dart/src/extension/NotifyChanges.dart';

/// Exception thrown when there is an error fetching data in the TDSController.
/// 
/// This exception can be used to indicate issues such as network failures,
/// invalid responses, or other problems encountered while attempting to
/// retrieve data from a source.
class TDSFetchDataException implements Exception {
  final _message;
  TDSFetchDataException([this._message]);

  String toString() {
    if (_message == null) return "Exception";
    return "Exception: $_message";
  }
}

/// A controller class for managing and notifying changes to a collection of [TDSElement]s.
/// 
/// Extends [NotifyChanges] to provide change notification functionality.
/// 
/// Type parameter [TDSElement] specifies the type of elements managed by this controller.
class TDSController<TDSElement> extends NotifyChanges {

 

  final Map<String, TDSElement> tdsDict = Map();

  final TDSRequest request;
  final String proxyHostName;

  /// Constructs a [TDSController] with the specified [type] and optional [proxyHostName].
  ///
  /// [type] defines the type of TDS request to be handled.
  /// [proxyHostName] is the hostname of the optional proxy server to be used. Defaults to empty string.
  TDSController(TDSRequestType type, [this.proxyHostName = '']) :
    request = TDSRequest(type, proxyHostName);


  /// Makes a full file request of all Metars
  Future<Map<String, TDSElement>> fullRequest() async {
    developer.log('#Metar_Parser fullRequest');
    var content = await request.readZippedFile();
    final file = content.toString();
    if (file.length < 100) {
      developer.log('ERROR file not found');
      throw new TDSFetchDataException("An error occured, file not found");
    }
    final map = request.parse(file);

    tdsDict.addAll(map.cast<String, TDSElement>());
    notifyListeners();
    return tdsDict;
  }

   /// Fetch METARs for a specific bounding box and update tdsDict.
  /// [lat0, lon0] is the southwest corner, [lat1, lon1] is the northeast corner.
  Future<Map<String, TDSElement>?> fetchByArea({
    required double lat0,
    required double lon0,
    required double lat1,
    required double lon1,
  }) async {
    developer.log('#Metar_Parser fetchByArea bbox=[$lat0,$lon0,$lat1,$lon1]');
    final map = await request.fetchByArea(
      lat0: lat0,
      lon0: lon0,
      lat1: lat1,
      lon1: lon1,
    );

    if (map != null) {
      tdsDict.clear();
      tdsDict.addAll(map.cast<String, TDSElement>());
      notifyListeners();
      return tdsDict;
    }
    return tdsDict;
  }
}

/// Controller class for handling operations related to [MetarTDS] objects.
/// 
/// Extends [TDSController] to provide specific functionality for METAR data.
/// Use this controller to manage, parse, and interact with METAR records.
class MetarController extends TDSController<MetarTDS>{
  /// The hostname of the optional proxy server to be used for requests.
  final String proxyHostName;

  /// Constructs a [MetarController] with the specified [proxyHostName].
  /// 
  /// Initializes the controller by calling the superclass constructor with
  /// [TDSRequestType.metar] and the provided [proxyHostName].
  ///
  /// [proxyHostName] is the hostname of the optional proxy server to be used for requests. Defaults to empty string.
  MetarController({this.proxyHostName = ''}) : super(TDSRequestType.metar, proxyHostName);
}



/// A controller class for handling TAF (Terminal Aerodrome Forecast) data,
/// extending the generic [TDSController] with [TafTDS] as the data source.
/// 
/// This class provides specialized logic and functionality for managing,
/// parsing, and interacting with TAF-related data within the application.
class TafController extends TDSController<TafTDS>{
  /// The hostname of the optional proxy server to be used for requests.
  final String proxyHostName;

  /// Creates a [TafController] instance with the specified [proxyHostName].
  ///
  /// Initializes the controller by calling the superclass constructor with
  /// [TDSRequestType.taf] as the request type and the provided [proxyHostName].
  ///
  /// [proxyHostName] is the hostname of the optional proxy server to be used for requests. Defaults to empty string.
  TafController({this.proxyHostName = ''}) : super(TDSRequestType.taf, proxyHostName);
}

/// A controller class for managing operations related to [StationTDS] entities.
/// 
/// Inherits from [TDSController] and provides specific functionality for
/// handling station data within the application.
class StationController extends TDSController<StationTDS>{

  /// The hostname of the optional proxy server to be used for requests.
  final String proxyHostName;

  /// Creates a [StationController] instance with the specified [proxyHostName].
  ///
  /// Calls the superclass constructor with [TDSRequestType.station] and the given [proxyHostName].
  ///
  /// [proxyHostName] is the hostname of the optional proxy server to be used for requests. Defaults to empty string.
  StationController({this.proxyHostName = ''}) : super(TDSRequestType.station, proxyHostName);
}



