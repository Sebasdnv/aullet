import 'package:flutter/material.dart';

Color parseHexColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6) buffer.write('FF');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}