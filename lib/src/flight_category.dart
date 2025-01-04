
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

     var limit = val.visibility;
     var lowest = val.lowestSignificantCloudBase;

     if (limit == null || lowest == null) {
        return FlightCategory.NONE;
     }

     if (limit < 1 || lowest < 500) {
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
   }


abstract class  FlightCategoryRelated {
  /// get visibilty in status miles SM
  double? get visibility;
  /// get lowest significant cloudbase in feet AGL
  int? get lowestSignificantCloudBase;
}


