# metar_parser_dart

A Dart package to parse aviation weather products from NOAA ADDS, including:

- METAR (observations)
- TAF (forecasts)
- Station metadata

The package supports both:

- Raw string parsing (`MetarRaw`, `TafRaw`)
- Remote fetch + typed models via controllers/providers (`MetarController`, `TafController`, `StationController`)

## Features

- Parse raw METAR and TAF strings into structured Dart models.
- Fetch METAR/TAF/Station data by ICAO, location, or area.
- Compute derived values such as cloud base, visibility, and flight category.
- Sort stations by geographic proximity.
- Works with Dart/Flutter projects.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  metar_parser_dart: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Quick Start

### 1) Parse a raw METAR string

```dart
import 'package:metar_parser_dart/metar_parser_dart.dart';

void main() {
  final metar = MetarRaw.parse(
    'METAR EDDV 151420Z AUTO 26005KT 9999 OVC022 09/06 Q1025 NOSIG',
  );

  print(metar.station_id);          // EDDV
  print(metar.flightCategory);      // e.g. MVFR
  print(metar.lowestSignificantCloudBase);
}
```

### 2) Fetch live METAR data for one station

```dart
import 'package:metar_parser_dart/metar_parser_dart.dart';

Future<void> main() async {
  final controller = MetarController();
  final metars = await controller.fetchByID('EDDV');

  final eddv = metars['EDDV'];
  if (eddv != null) {
    print(eddv.raw_text);
    print(eddv.flightCategory);
  }
}
```

### 3) Fetch by area

```dart
import 'package:latlong2/latlong.dart';
import 'package:metar_parser_dart/metar_parser_dart.dart';

Future<void> main() async {
  final controller = StationController();
  final stations = await controller.fetchByArea(
    sw: const LatLng(52.3, 9.5),
    ne: const LatLng(52.6, 9.9),
  );

  print(stations.length);
}
```

## Public API

Main exports live in `lib/metar_parser_dart.dart`:

- TDS models: `MetarTDS`, `TafTDS`, `StationTDS`
- Raw models: `MetarRaw`, `TafRaw`
- Controllers/providers: `TDSController`, `MetarController`, `TafController`, `StationController`
- Supporting enums/models such as `FlightCategory`

## Development

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## GitHub Deployment Checklist

This repository includes:

- CI workflow in `.github/workflows/dart-ci.yml`
- Issue templates in `.github/ISSUE_TEMPLATE/`
- Pull request template in `.github/pull_request_template.md`
- Contribution guide in `CONTRIBUTING.md`

## Versioning and Releases

- Update version in `pubspec.yaml`
- Add release notes in `CHANGELOG.md`
- Create a Git tag (`vX.Y.Z`) and GitHub Release

## License

MIT License. See `LICENSE`.
