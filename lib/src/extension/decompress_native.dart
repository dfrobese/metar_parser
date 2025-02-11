import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'dart:developer' as developer;

/// Decompresses Zlib data using archive package support.
String decompressZlib(Uint8List compressedData) {
  developer.log("decompressZlib native");
  final decoder = GZipDecoder();
  final bytes = decoder.decodeBytes(compressedData);
  return utf8.decode(bytes);
}
