import 'lib/src/TDSRequest.dart';
import 'lib/src/MetarTDS.dart';
import 'lib/src/TafTDS.dart';

void main() {
  print('Hello, World!');

  TDSRequest request = TDSRequest();

  var file = request.readFile(Config.metar);
  file.then((content) => MetarTDS.parse(content.toString()));

  file = request.readFile(Config.taf);
  file.then((content) => TafTDS.parse(content.toString()));
}