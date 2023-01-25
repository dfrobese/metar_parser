import 'lib/src/TDSRequest.dart';
import 'lib/src/MetarTDS.dart';


void main() {
  print('Hello, World!');

  TDSRequest request = TDSRequest();

  var file = request.readFile(Config.metar);
  file.then((content) => MetarTDS.parse(content.toString()));

}