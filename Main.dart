import 'lib/src/TDSRequest.dart';
import 'lib/src/MetarTDS.dart';
import 'lib/src/TafTDS.dart';

void main() {
  print('Hello, World!');

  TDSRequest request = TDSRequest.metar;

  var file = request.readFile();
  file.then((content) => request.parse(content.toString()));

  request = TDSRequest.taf;
  file = request.readFile();
  file.then((content) => request.parse(content.toString()));
}