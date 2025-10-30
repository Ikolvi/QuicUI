/// Dart extension methods for convenient operations
///
/// This module provides extension methods that enhance standard Dart types
/// with utility methods commonly used in QuicUI applications.
///
/// ## Extension Categories
///
/// ```
/// StringExtension
///   ├→ isEmpty / isNotEmpty
///   ├→ capitalize
///   └→ Type conversion (toInt, toDouble, toBool)
///
/// ListExtension
///   ├→ isEmpty / isNotEmpty
///   ├→ firstOrNull / lastOrNull
///   └→ Null-safe operations
///
/// MapExtension
///   ├→ isEmpty / isNotEmpty
///   └→ getValue with defaults
///
/// DurationExtension
///   ├→ ms / seconds conversion
///   └→ hasPassed comparison
/// ```
///
/// ## Usage Examples
///
/// ### String Extensions
/// ```dart
/// final text = "  hello world  ";
/// print(text.isEmpty);           // false
/// print(text.isNotEmpty);         // true
/// print(text.capitalize);         // "Hello world"
/// print("123".toInt());           // 123
/// print("3.14".toDouble());       // 3.14
/// print("true".toBool());         // true
/// ```
///
/// ### List Extensions
/// ```dart
/// final list = [1, 2, 3];
/// print(list.isEmpty);            // false
/// print(list.firstOrNull);        // 1
/// print(list.lastOrNull);         // 3
/// final emptyList = null;
/// print(emptyList.isEmpty);       // true
/// print(emptyList.firstOrNull);   // null
/// ```
///
/// ### Map Extensions
/// ```dart
/// final map = {'key': 'value'};
/// print(map.isEmpty);             // false
/// print(map.getValue('key'));     // 'value'
/// print(map.getValue('missing', defaultValue: 'default')); // 'default'
/// ```
///
/// ### Duration Extensions
/// ```dart
/// final dur = Duration(seconds: 5);
/// print(dur.ms);                  // 5000
/// print(dur.seconds);             // 5.0
/// print(dur.hasPassed(DateTime.now().subtract(Duration(seconds: 10)))); // true
/// ```
///
/// ## Benefits
///
/// - **Concise Code**: Write less boilerplate
/// - **Safe Operations**: Null-safe methods prevent crashes
/// - **Consistency**: Common patterns available everywhere
/// - **Type Safety**: Static typing preserved
/// - **Performance**: No runtime overhead vs manual checks
///
/// See also:
/// - [validators]: Data validation utilities
/// - [logger_util]: Logging utilities

/// String extensions for common operations
///
/// Provides utility methods for string manipulation, type conversion,
/// and null-safe checking operations.
///
/// Example:
/// ```dart
/// final name = "  john doe  ";
/// print(name.isNotEmpty);     // true
/// print(name.capitalize);      // "John doe"
/// print("42".toInt() + 8);     // 50
/// ```
extension StringExtension on String {
  /// Check if string is empty after trimming whitespace
  ///
  /// Returns true if string is empty or contains only whitespace.
  /// Handles the common case where user input contains surrounding spaces.
  ///
  /// ## Returns
  /// - true: String is empty or whitespace-only
  /// - false: String contains non-whitespace characters
  ///
  /// ## Example
  /// ```dart
  /// "hello".isEmpty             // false
  /// "   ".isEmpty               // true
  /// "".isEmpty                  // true
  /// ```
  bool get isEmpty => trim().isEmpty;

  /// Check if string is not empty after trimming whitespace
  ///
  /// Convenience property, inverse of isEmpty.
  /// Useful for validating user input.
  ///
  /// ## Returns
  /// - true: String contains non-whitespace characters
  /// - false: String is empty or whitespace-only
  ///
  /// ## Example
  /// ```dart
  /// "hello".isNotEmpty          // true
  /// "   ".isNotEmpty            // false
  /// ```
  bool get isNotEmpty => trim().isNotEmpty;

  /// Capitalize first letter of string
  ///
  /// Converts first character to uppercase, leaves rest unchanged.
  /// Useful for formatting names and titles.
  ///
  /// ## Returns
  /// String with first character capitalized
  ///
  /// ## Throws
  /// - [RangeError]: Called on empty string
  ///
  /// ## Example
  /// ```dart
  /// "hello".capitalize        // "Hello"
  /// "world".capitalize        // "World"
  /// "iOS app".capitalize      // "IOS app"
  /// ```
  ///
  /// ## Note
  /// Only affects first character. For full uppercase use `toUpperCase()`.
  String get capitalize => this[0].toUpperCase() + substring(1);

  /// Parse string to integer
  ///
  /// Safely converts string to int without throwing.
  /// Returns null if parsing fails.
  ///
  /// ## Returns
  /// Parsed integer or null if invalid format
  ///
  /// ## Example
  /// ```dart
  /// "123".toInt()       // 123
  /// "3.14".toInt()      // null
  /// "invalid".toInt()   // null
  /// "-42".toInt()       // -42
  /// ```
  ///
  /// See also:
  /// - [toDouble]: Parse as double
  /// - [toBool]: Parse as bool
  int? toInt() => int.tryParse(this);

  /// Parse string to double
  ///
  /// Safely converts string to double without throwing.
  /// Returns null if parsing fails.
  ///
  /// ## Returns
  /// Parsed double or null if invalid format
  ///
  /// ## Example
  /// ```dart
  /// "3.14".toDouble()       // 3.14
  /// "123".toDouble()        // 123.0
  /// "1.5e2".toDouble()      // 150.0
  /// "invalid".toDouble()    // null
  /// ```
  ///
  /// See also:
  /// - [toInt]: Parse as int
  /// - [toBool]: Parse as bool
  double? toDouble() => double.tryParse(this);

  /// Parse string to boolean
  ///
  /// Converts common boolean representations to bool value.
  /// Case-insensitive matching.
  ///
  /// ## Recognized True Values
  /// - "true" (case-insensitive)
  /// - "1"
  /// - "yes" (case-insensitive)
  ///
  /// ## Recognized False Values
  /// - "false" (case-insensitive)
  /// - "0"
  /// - "no" (case-insensitive)
  ///
  /// ## Returns
  /// - true: Matched true values
  /// - false: Matched false values
  /// - null: Unknown value
  ///
  /// ## Example
  /// ```dart
  /// "true".toBool()         // true
  /// "FALSE".toBool()        // false
  /// "1".toBool()            // true
  /// "0".toBool()            // false
  /// "yes".toBool()          // true
  /// "no".toBool()           // false
  /// "maybe".toBool()        // null
  /// ```
  ///
  /// ## Use Cases
  /// - Parsing form inputs
  /// - Configuration values
  /// - API responses
  ///
  /// See also:
  /// - [toInt]: Parse as int
  /// - [toDouble]: Parse as double
  bool? toBool() {
    final lower = toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no') return false;
    return null;
  }
}

/// List extensions for null-safe operations
///
/// Provides utility methods for safely accessing list elements
/// when list itself might be null.
///
/// Example:
/// ```dart
/// List<String>? items;
/// print(items.isEmpty);        // true (safe, doesn't throw)
/// print(items.firstOrNull);    // null (safe)
/// ```
extension ListExtension<T> on List<T>? {
  /// Check if list is empty or null
  ///
  /// Returns true if list is null or contains no elements.
  /// Safe to call on null lists without throwing.
  ///
  /// ## Returns
  /// - true: List is null or empty
  /// - false: List contains elements
  ///
  /// ## Example
  /// ```dart
  /// final List<int>? list = null;
  /// print(list.isEmpty);        // true
  ///
  /// final list2 = <int>[];
  /// print(list2.isEmpty);       // true
  ///
  /// final list3 = [1, 2, 3];
  /// print(list3.isEmpty);       // false
  /// ```
  ///
  /// ## Note
  /// This is the null-safe equivalent of `list?.isEmpty ?? true`
  bool get isEmpty => this == null || this!.isEmpty;

  /// Check if list is not empty and not null
  ///
  /// Returns true if list exists and contains elements.
  /// Safe to call on null lists.
  ///
  /// ## Returns
  /// - true: List exists and contains elements
  /// - false: List is null or empty
  ///
  /// ## Example
  /// ```dart
  /// final List<int>? list = [1, 2, 3];
  /// if (list.isNotEmpty) {
  ///   process(list!);
  /// }
  /// ```
  bool get isNotEmpty => this != null && this!.isNotEmpty;

  /// Get first element or null
  ///
  /// Safely retrieves first element without throwing.
  /// Returns null if list is null or empty.
  ///
  /// ## Returns
  /// First element or null if not available
  ///
  /// ## Example
  /// ```dart
  /// final List<int>? list = null;
  /// print(list.firstOrNull);    // null
  ///
  /// final list2 = [1, 2, 3];
  /// print(list2.firstOrNull);   // 1
  /// ```
  ///
  /// ## Note
  /// Equivalent to: `list?.isEmpty ?? true ? null : list.first`
  ///
  /// See also:
  /// - [lastOrNull]: Get last element safely
  T? get firstOrNull => isEmpty ? null : this!.first;

  /// Get last element or null
  ///
  /// Safely retrieves last element without throwing.
  /// Returns null if list is null or empty.
  ///
  /// ## Returns
  /// Last element or null if not available
  ///
  /// ## Example
  /// ```dart
  /// final List<String>? items = ["a", "b", "c"];
  /// print(items.lastOrNull);    // "c"
  ///
  /// final empty = <String>[];
  /// print(empty.lastOrNull);    // null
  /// ```
  ///
  /// See also:
  /// - [firstOrNull]: Get first element safely
  T? get lastOrNull => isEmpty ? null : this!.last;
}

/// Map extensions for null-safe operations
///
/// Provides utility methods for safely accessing map values
/// when map itself might be null.
///
/// Example:
/// ```dart
/// Map<String, String>? data;
/// print(data.isEmpty);                    // true
/// print(data.getValue('key'));            // null
/// print(data.getValue('key', defaultValue: 'N/A')); // 'N/A'
/// ```
extension MapExtension<K, V> on Map<K, V>? {
  /// Check if map is empty or null
  ///
  /// Returns true if map is null or contains no entries.
  /// Safe to call on null maps.
  ///
  /// ## Returns
  /// - true: Map is null or empty
  /// - false: Map contains entries
  ///
  /// ## Example
  /// ```dart
  /// final Map<String, int>? map = null;
  /// print(map.isEmpty);         // true
  ///
  /// final map2 = <String, int>{};
  /// print(map2.isEmpty);        // true
  ///
  /// final map3 = {'a': 1};
  /// print(map3.isEmpty);        // false
  /// ```
  bool get isEmpty => this == null || this!.isEmpty;

  /// Check if map is not empty and not null
  ///
  /// Returns true if map exists and contains entries.
  ///
  /// ## Returns
  /// - true: Map exists and contains entries
  /// - false: Map is null or empty
  ///
  /// ## Example
  /// ```dart
  /// final Map<String, int>? data = {'count': 5};
  /// if (data.isNotEmpty) {
  ///   print('Map has data');
  /// }
  /// ```
  bool get isNotEmpty => this != null && this!.isNotEmpty;

  /// Get value by key with optional default
  ///
  /// Safely retrieves value without throwing.
  /// Returns default value if key not found.
  ///
  /// ## Parameters
  /// - [key]: Key to lookup
  /// - [defaultValue]: Value to return if key not found (default: null)
  ///
  /// ## Returns
  /// Value for key or defaultValue if not found
  ///
  /// ## Example
  /// ```dart
  /// final Map<String, String>? config = {'theme': 'dark'};
  /// print(config.getValue('theme'));              // 'dark'
  /// print(config.getValue('lang'));               // null
  /// print(config.getValue('lang', defaultValue: 'en')); // 'en'
  ///
  /// final Map? nullMap = null;
  /// print(nullMap.getValue('key'));               // null
  /// print(nullMap.getValue('key', defaultValue: 'default')); // 'default'
  /// ```
  ///
  /// ## Note
  /// Equivalent to: `this?[key] ?? defaultValue`
  V? getValue(K key, {V? defaultValue}) {
    return this?[key] ?? defaultValue;
  }
}

/// Duration extensions for convenient operations
///
/// Provides utility methods for working with durations
/// including conversions and comparisons.
///
/// Example:
/// ```dart
/// final delay = Duration(seconds: 5);
/// print(delay.ms);            // 5000
/// print(delay.seconds);       // 5.0
/// ```
extension DurationExtension on Duration {
  /// Convert duration to milliseconds
  ///
  /// Shorthand for `inMilliseconds`.
  /// Useful in animation and timing contexts.
  ///
  /// ## Returns
  /// Duration in milliseconds as integer
  ///
  /// ## Example
  /// ```dart
  /// Duration(seconds: 1).ms        // 1000
  /// Duration(milliseconds: 500).ms // 500
  /// Duration(minutes: 1).ms        // 60000
  /// ```
  ///
  /// ## Common Uses
  /// - `Future.delayed(Duration(seconds: 2))`
  /// - `Animation duration values`
  /// - `setTimeout equivalent`
  int get ms => inMilliseconds;

  /// Convert duration to seconds
  ///
  /// Converts to seconds as double for precision.
  /// More readable than `inMicroseconds / 1000000`.
  ///
  /// ## Returns
  /// Duration in seconds as double
  ///
  /// ## Example
  /// ```dart
  /// Duration(seconds: 5).seconds            // 5.0
  /// Duration(milliseconds: 2500).seconds    // 2.5
  /// Duration(minutes: 1).seconds            // 60.0
  /// ```
  ///
  /// See also:
  /// - [ms]: Get milliseconds
  double get seconds => inMicroseconds / 1000000;

  /// Check if duration has passed since given time
  ///
  /// Compares duration with time elapsed since `since` parameter.
  /// Useful for timeout detection and rate limiting.
  ///
  /// ## Parameters
  /// - [since]: Reference time to measure from
  ///
  /// ## Returns
  /// - true: More time has passed than duration
  /// - false: Less time has passed
  ///
  /// ## Example
  /// ```dart
  /// final lastCheck = DateTime.now().subtract(Duration(seconds: 5));
  /// final timeout = Duration(seconds: 10);
  ///
  /// if (!timeout.hasPassed(lastCheck)) {
  ///   print('Still within timeout');
  /// }
  ///
  /// // For rate limiting
  /// final lastRequest = DateTime.now().subtract(Duration(milliseconds: 100));
  /// final minInterval = Duration(milliseconds: 500);
  ///
  /// if (minInterval.hasPassed(lastRequest)) {
  ///   performRequest();
  /// }
  /// ```
  ///
  /// ## Use Cases
  /// - Timeout detection
  /// - Rate limiting
  /// - Debounce/throttle logic
  /// - Activity timeout
  bool hasPassed(DateTime since) {
    return DateTime.now().difference(since) >= this;
  }
}
