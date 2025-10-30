/// QuicUI App widget


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main QuicUI application widget
class QuicUIApp extends StatelessWidget {
  final String title;
  final ThemeData? theme;
  final Widget? home;

  const QuicUIApp({
    Key? key,
    this.title = 'QuicUI',
    this.theme,
    this.home,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: theme ?? ThemeData(primarySwatch: Colors.blue),
      home: home ?? const Scaffold(
        body: Center(
          child: Text('QuicUI App'),
        ),
      ),
    );
  }
}
