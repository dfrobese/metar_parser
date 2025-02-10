import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Decompresses Zlib data using Dart's built-in `dart:io` support.
String decompressZlib(Uint8List compressedData) {
  final decoder = GZipDecoder();
  final bytes = decoder.decodeBytes(compressedData);
  return utf8.decode(bytes);
}
