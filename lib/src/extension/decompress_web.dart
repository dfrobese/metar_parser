import 'package:archive/archive.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;

/// Decompresses Zlib data using JavaScript's Pako.js in Flutter Web.
String decompressZlib(Uint8List compressedData) {
  developer.log("decompressZlib web");
  final decoder = GZipDecoderWeb();
  final bytes = decoder.decodeBytes(compressedData);
  return utf8.decode(bytes);
}
