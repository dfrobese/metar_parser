import 'dart:js' as js;
import 'dart:typed_data';
import 'dart:convert';

/// Decompresses Zlib data using JavaScript's Pako.js in Flutter Web.
String decompressZlib(Uint8List compressedData) {
  var jsArray = js.JsObject.jsify(compressedData);
  var result = js.context.callMethod('pako.inflate', [jsArray, {'to': 'string'}]);
  return result as String;
}
