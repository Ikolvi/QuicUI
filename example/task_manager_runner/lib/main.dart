import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quicui/quicui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final jsonString = await rootBundle.loadString('assets/screens.json');
  final appJson = jsonDecode(jsonString) as Map<String, dynamic>;
  
  // Pass navigation callback to JSON for screen switching
  appJson['onNavigateTo'] = (String screen, {Map<String, dynamic>? data}) {
    // Navigation state will be managed by UIRenderer through the callback system
  };
  
  runApp(UIRenderer.render(appJson));
}
