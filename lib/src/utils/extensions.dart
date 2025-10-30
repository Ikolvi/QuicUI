/// Extension methods


/// String extensions
extension StringExtension on String {
  /// Check if string is empty or null
  bool get isEmpty => trim().isEmpty;

  /// Check if string is not empty
  bool get isNotEmpty => trim().isNotEmpty;

  /// Capitalize first letter
  String get capitalize => this[0].toUpperCase() + substring(1);

  /// Convert to int
  int? toInt() => int.tryParse(this);

  /// Convert to double
  double? toDouble() => double.tryParse(this);

  /// Convert to bool
  bool? toBool() {
    final lower = toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    return null;
  }
}

/// List extensions
extension ListExtension<T> on List<T>? {
  /// Check if list is empty or null
  bool get isEmpty => this == null || this!.isEmpty;

  /// Check if list is not empty
  bool get isNotEmpty => this != null && this!.isNotEmpty;

  /// Get first element or null
  T? get firstOrNull => isEmpty ? null : this!.first;

  /// Get last element or null
  T? get lastOrNull => isEmpty ? null : this!.last;
}

/// Map extensions
extension MapExtension<K, V> on Map<K, V>? {
  /// Check if map is empty or null
  bool get isEmpty => this == null || this!.isEmpty;

  /// Check if map is not empty
  bool get isNotEmpty => this != null && this!.isNotEmpty;

  /// Get value safely
  V? getValue(K key, {V? defaultValue}) {
    return this?[key] ?? defaultValue;
  }
}

/// Duration extensions
extension DurationExtension on Duration {
  /// Convert to milliseconds as int
  int get ms => inMilliseconds;

  /// Convert to seconds as double
  double get seconds => inMicroseconds / 1000000;

  /// Check if duration has passed
  bool hasPassed(DateTime since) {
    return DateTime.now().difference(since) >= this;
  }
}
