/// Screen view widget


import 'package:flutter/material.dart';

/// Widget for displaying a screen
class ScreenView extends StatelessWidget {
  final Map<String, dynamic> screenData;
  final VoidCallback? onRefresh;

  const ScreenView({
    Key? key,
    required this.screenData,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh?.call();
      },
      child: const Center(
        child: Text('Screen View'),
      ),
    );
  }
}
