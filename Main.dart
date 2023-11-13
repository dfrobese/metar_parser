import 'lib/src/TDSRequest.dart';


void main() {
  print('Hello, World!');

  TDSRequest request = TDSRequest(TDSRequestType.metar);

  var file = request.readFile();
  file.then((content) => request.parse(content.toString()));

  request = TDSRequest(TDSRequestType.taf);
  file = request.readFile();
  file.then((content) => request.parse(content.toString()));
}