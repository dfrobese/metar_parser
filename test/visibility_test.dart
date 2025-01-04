import 'package:metar_parser_dart/src/units/distance_unit.dart';
import 'package:metar_parser_dart/src/visibility.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('Visibility Parsing', () {
    test('Parses visibility in statute miles (SM)', () {
      final visibility = Visibility.parse("6SM");
      expect(visibility.minVisibility, 6.0);
      expect(visibility.maxVisibility, isNull);
      expect(visibility.unit, DistanceUnit.SM);
      expect(visibility.isGreaterThanMin, isFalse);
      expect(visibility.minInMiles, 6.0);
    });

    test('Parses greater-than visibility in SM', () {
      final visibility = Visibility.parse("P6SM");
      expect(visibility.minVisibility, 6.0);
      expect(visibility.maxVisibility, isNull);
      expect(visibility.unit, DistanceUnit.SM);
      expect(visibility.isGreaterThanMin, isTrue);
      expect(visibility.minInMiles, 6.0);
    });

    test('Parses fractional visibility in SM', () {
      final visibility = Visibility.parse("1/2SM");
      expect(visibility.minVisibility, 0.5);
      expect(visibility.maxVisibility, isNull);
      expect(visibility.unit, DistanceUnit.SM);
      expect(visibility.isGreaterThanMin, isFalse);
      expect(visibility.minInMiles, 0.5);
    });

    test('Parses fractional visibility in SM', () {
      final visibility = Visibility.parse("1 1/2SM");
      expect(visibility.minVisibility, 1.5);
      expect(visibility.maxVisibility, isNull);
      expect(visibility.unit, DistanceUnit.SM);
      expect(visibility.isGreaterThanMin, isFalse);
      expect(visibility.minInMiles, 1.5);
    });

    test('Parses visibility in meters', () {
      final visibility = Visibility.parse("2000");
      expect(visibility.minVisibility, 2000.0);
      expect(visibility.maxVisibility, isNull);
      expect(visibility.unit, DistanceUnit.M);
      expect(visibility.isGreaterThanMin, isFalse);
      expect(visibility.minInMiles, closeTo(1.2427, 0.0001));
    });

    test('Parses range visibility in meters', () {
      final visibility = Visibility.parse("2000 4000");
      expect(visibility.minVisibility, 2000.0);
      expect(visibility.maxVisibility, 4000.0);
      expect(visibility.unit, DistanceUnit.M);
      expect(visibility.isGreaterThanMin, isFalse);
      expect(visibility.minInMiles, closeTo(1.2427, 0.0001));
      expect(visibility.maxInMiles, closeTo(2.4855, 0.0001));
    });

    test('Throws error for invalid visibility string', () {
      expect(() => Visibility.parse("INVALID"), throwsArgumentError);
    });
  });
}
