/// Theme configuration model


/// Theme configuration for screens
class ThemeConfig {
  /// Primary color
  final int primaryColor;

  /// Secondary color
  final int secondaryColor;

  /// Text color
  final int textColor;

  /// Background color
  final int backgroundColor;

  /// Font family
  final String fontFamily;

  /// Base font size
  final double baseFontSize;

  ThemeConfig({
    this.primaryColor = 0xFF2196F3,
    this.secondaryColor = 0xFFFFC107,
    this.textColor = 0xFF212121,
    this.backgroundColor = 0xFFFFFFFF,
    this.fontFamily = 'Roboto',
    this.baseFontSize = 14.0,
  });

  /// Creates a copy with modified values
  ThemeConfig copyWith({
    int? primaryColor,
    int? secondaryColor,
    int? textColor,
    int? backgroundColor,
    String? fontFamily,
    double? baseFontSize,
  }) {
    return ThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      baseFontSize: baseFontSize ?? this.baseFontSize,
    );
  }
}
