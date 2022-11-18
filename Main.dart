import 'lib/src/TDSRequest.dart';
import 'lib/src/Metar.dart';


void main() {
  print('Hello, World!');

  TDSRequest request = TDSRequest();

  var file = request.readFile(Config.metar);
  file.then((content) => Metar.parse(content.toString()));

}