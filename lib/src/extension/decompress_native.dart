import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// Decompresses Zlib data using Dart's built-in `dart:io` support.
String decompressZlib(Uint8List compressedData) {
  List<int> decompressed = zlib.decode(compressedData);
  return utf8.decode(decompressed);
}
