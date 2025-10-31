import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() async {
  final jsonString = await rootBundle.loadString('assets/screens.json');
  final appJson = jsonDecode(jsonString) as Map<String, dynamic>;
  runApp(UIRenderer.render(appJson));
}
