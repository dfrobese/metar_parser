
import 'package:metar_parser_dart/src/tds_parser/forecast_tds.dart';
import 'dart:developer' as developer;

/// class to hande the flight category of a Metar
enum FlightCategory {
  VFR, MVFR, IFR, LIFR, NONE ;


   factory FlightCategory.parse(String str) {
     if (str.length<3) {
       return FlightCategory.NONE;
     }
     var fc = FlightCategory.values.firstWhere((e) => e.name == str.toUpperCase());
     return fc;
   }

   ///The U.S. system from NOAA defines 4 different rules:
   ///Rule           Visibility          Ceiling
   /// Category	Color	Ceiling	 	Visibility
   /// LIFR Low Instrument Flight Rules Magenta	below 500 feet AGL	and/or	less than 1 mile
   /// IFR Instrument Flight Rules	Red	500 to below 1,000 feet AGL	and/or	1 mile to less than 3 miles
   /// MVFR Marginal Visual Flight Rules	Blue	1,000 to 3,000 feet AGL	and/or	3 to 5 miles
   /// VFR Visual Flight Rules	Green	greater than 3,000 feet AGL	and	greater than 5 miles
  factory FlightCategory.calc(FlightCategoryRelated val) {

     var limit = val.lowestVisibility;
     var lowest = val.lowestSignificantCloudBase;

     if (limit == null && lowest == null) {
       return FlightCategory.NONE;
     } else if (limit == null && lowest != null) {
        return  (lowest < 500) ? FlightCategory.LIFR : FlightCategory.NONE;
     } else if (lowest == null && limit != null) {
       return  (limit < 1) ? FlightCategory.LIFR : FlightCategory.NONE;
     }

     if (limit! < 1 || lowest! < 500) {
       return FlightCategory.LIFR;
     } else if (limit < 3) {
       return FlightCategory.IFR;
     } else if (limit <= 5) {
       if (lowest < 1000) {
         return FlightCategory.IFR;
       }
       return FlightCategory.MVFR;
     } else {
       if (lowest < 1000) {
         return FlightCategory.IFR;
       } else if (lowest <= 3000) {
         return FlightCategory.MVFR;
       } else {
         return FlightCategory.VFR;
       }
     }
   }

   static List<FlightCategory> calculateFlightCategories(
       List<FlightCategoryRelated> entries) {

     if (entries.isEmpty) {
       return [];
     }

     // List to store the results
     final List<FlightCategory> results = [];

     // Variables to store the predecessor's values
     double? lastVisibility;
     int? lastCloudBase;

     for (final entry in entries) {
       // Use current values if not null, otherwise fallback to the last known values
       final currentVisibility = entry.lowestVisibility ?? lastVisibility;
       final currentCloudBase = entry.lowestSignificantCloudBase ?? lastCloudBase;

       if (currentVisibility == null && currentCloudBase == null) {
         // no calculation possible
         entry.flightCategory = FlightCategory.NONE;
         developer.log(
             "Unable to calculate FlightCategory; insufficient data for entry: $entry");

       } else {
        // Update the entry with fallback values
        final adjustedEntry = _AdjustedFlightCategoryRelated(
          currentVisibility,
          currentCloudBase,
        );
        // use the value to set flightcategory
        final flightCategory = FlightCategory.calc(adjustedEntry);
        entry.flightCategory = flightCategory;

        // Update the last known values only if none temporary
        if (entry.changeIndicator != ChangeIndicator.TEMPO &&
            entry.changeIndicator != ChangeIndicator.INTER) {
          if (currentVisibility != null) {
            lastVisibility = currentVisibility;
          }
          if (currentCloudBase != null) {
              lastCloudBase = currentCloudBase;
          }
        }
      }
    }

     return results;
   }
}

/// Helper class to wrap adjusted FlightCategoryRelated values
class _AdjustedFlightCategoryRelated implements FlightCategoryRelated {
  @override
  final double? lowestVisibility;

  @override
  final int? lowestSignificantCloudBase;

  _AdjustedFlightCategoryRelated(this.lowestVisibility, this.lowestSignificantCloudBase);

  @override late FlightCategory flightCategory;

  @override ChangeIndicator get changeIndicator => ChangeIndicator.TAF;
}

/// abstract class to calculate the flight category for forecasts and metars in the same way
abstract class  FlightCategoryRelated {
  /// get visibilty in status miles SM
  double? get lowestVisibility;
  /// get lowest significant cloudbase in feet AGL
  int? get lowestSignificantCloudBase;
  /// flight category placeholder
  late FlightCategory flightCategory;
  /// change indicator
  ChangeIndicator get changeIndicator;
}


