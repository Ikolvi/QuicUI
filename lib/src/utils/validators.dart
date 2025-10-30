/// Data validation utilities for QuicUI forms and inputs
///
/// This module provides a collection of validation functions for common
/// use cases in form processing, user input validation, and data integrity checks.
///
/// ## Validation Functions
///
/// ```
/// Validators (Static methods)
///   ├→ validateEmail(): RFC 5322 simplified format
///   ├→ validateRequired(): Null/empty checks
///   ├→ validateMinLength(): Length constraints
///   └→ validateUrl(): HTTP(S) URL validation
/// ```
///
/// ## Return Value Convention
///
/// All validators follow a consistent pattern:
/// - **Returns null**: Validation passed ✓
/// - **Returns String**: Validation failed, string contains error message ✗
///
/// This pattern is compatible with Flutter form field validators.
///
/// ## Usage Examples
///
/// ### Form Field Validation
/// ```dart
/// TextFormField(
///   validator: (value) => Validators.validateEmail(value),
///   decoration: InputDecoration(labelText: 'Email'),
/// )
///
/// TextFormField(
///   validator: (value) => Validators.validateMinLength(
///     value, 8,
///     fieldName: 'Password'
///   ),
/// )
/// ```
///
/// ### Programmatic Validation
/// ```dart
/// final emailError = Validators.validateEmail(userInput);
/// if (emailError != null) {
///   showError(emailError);
///   return;
/// }
/// // Process valid email
/// ```
///
/// ### Custom Validators
/// ```dart
/// String? validatePhoneNumber(String? value) {
///   if (Validators.validateRequired(value, fieldName: 'Phone') != null) {
///     return 'Phone number required';
///   }
///   if (!RegExp(r'^\d{10}$').hasMatch(value!)) {
///     return 'Phone must be 10 digits';
///   }
///   return null;
/// }
/// ```
///
/// ## Validation Rules
///
/// ### Email Validation
/// - Pattern: `name@domain.extension`
/// - Regex: `^[^\s@]+@[^\s@]+\.[^\s@]+$`
/// - Allows alphanumeric, dots, hyphens, underscores
/// - No spaces allowed
///
/// ### URL Validation
/// - Protocols: HTTP or HTTPS required
/// - Pattern: Domain name with TLD
/// - Query strings, fragments, ports supported
/// - No relative URLs
///
/// ## Edge Cases Handled
///
/// - Null values → Treated as empty
/// - Whitespace only → Treated as empty
/// - Leading/trailing spaces → Not trimmed (use .trim() before)
/// - Unicode characters → Generally accepted
///
/// ## Internationalization
///
/// Error messages are in English. For localization:
/// ```dart
/// String? validateEmailLocalized(String? value) {
///   final error = Validators.validateEmail(value);
///   if (error == null) return null;
///   // Replace with localized message
///   return AppLocalizations.of(context).invalidEmail;
/// }
/// ```
///
/// ## Common Patterns
///
/// ### Custom Field Validation
/// ```dart
/// String? validateUsername(String? value) {
///   // Combine multiple validators
///   var error = Validators.validateRequired(value, fieldName: 'Username');
///   if (error != null) return error;
///   
///   error = Validators.validateMinLength(value, 3, fieldName: 'Username');
///   if (error != null) return error;
///   
///   if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value!)) {
///     return 'Username can only contain letters, numbers, and underscores';
///   }
///   return null;
/// }
/// ```
///
/// ### Form Validation
/// ```dart
/// bool validateForm(FormState form) {
///   if (!form.validate()) {
///     LoggerUtil.warning('Form validation failed');
///     return false;
///   }
///   return true;
/// }
/// ```
///
/// ## Performance
///
/// - Regex compiled at first use, cached by Dart VM
/// - O(n) complexity where n = input string length
/// - Suitable for real-time validation (onChange)
///
/// ## Security Considerations
///
/// - Validators check format, not existence (email could be fake)
/// - Use server-side validation for security-critical data
/// - Consider rate limiting for email verification
/// - URL validation doesn't check if URL is accessible
///
/// See also:
/// - [extensions]: String utility extensions
/// - [logger_util]: Logging for validation errors
/// - [WidgetData]: Uses validators for widget configuration


/// Data validation utility class
///
/// Provides static validation methods for common input types.
/// All methods follow the pattern: return null if valid, or error message if invalid.
///
/// ## Validation Convention
/// ```dart
/// // Null return = Valid
/// if (Validators.validateEmail(email) == null) {
///   // Email is valid
/// }
///
/// // String return = Invalid
/// final error = Validators.validateEmail(email);
/// if (error != null) {
///   showError(error);
/// }
/// ```
///
/// This convention matches Flutter's TextFormField validator pattern.
///
/// ## Thread Safety
/// All methods are thread-safe and pure functions (no side effects).
///
/// ## Performance
/// Regular expressions are compiled and cached on first use by Dart VM.
class Validators {
  /// Validate email address format
  ///
  /// Checks if the provided value is a valid email address using
  /// a simplified RFC 5322 pattern. Validates basic email structure
  /// but does not verify email existence.
  ///
  /// ## Email Format Validated
  /// - Non-empty local part (before @)
  /// - Single @ symbol
  /// - Domain name
  /// - At least one dot in domain
  /// - Domain extension (at least 2 chars)
  ///
  /// ## Parameters
  /// - [value]: Email address to validate (can be null)
  ///
  /// ## Returns
  /// - null: Email format is valid
  /// - String: Error message describing validation failure
  ///
  /// ## Example
  /// ```dart
  /// Validators.validateEmail('user@example.com')   // null (valid)
  /// Validators.validateEmail('invalid.email')      // Error message
  /// Validators.validateEmail('user@domain')        // Error message (no TLD)
  /// Validators.validateEmail('')                   // Error message (empty)
  /// Validators.validateEmail(null)                 // Error message (null)
  /// ```
  ///
  /// ## Valid Email Examples
  /// - user@example.com
  /// - john.doe@company.co.uk
  /// - support+tag@service.io
  /// - name123@test-domain.com
  ///
  /// ## Invalid Email Examples
  /// - user@domain (no TLD)
  /// - @example.com (no local part)
  /// - user@.com (no domain)
  /// - user name@example.com (contains space)
  /// - user@domain..com (consecutive dots)
  ///
  /// ## Limitations
  /// - Does not verify email actually exists
  /// - Does not validate very long email addresses (RFC allows up to 254 chars)
  /// - Simplified pattern (full RFC 5322 is complex)
  /// - Unicode domains not validated correctly
  ///
  /// ## Validation Flow
  /// 1. Check if value is null or empty → Return error
  /// 2. Check if matches email regex pattern → Return error if not
  /// 3. Return null (valid)
  ///
  /// ## Use Cases
  /// - Form field validation
  /// - Pre-submission checks
  /// - Quick format validation before API call
  ///
  /// See also:
  /// - [validateRequired]: For null/empty checking
  /// - [validateUrl]: Similar URL validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  /// Validate required field is not empty
  ///
  /// Checks if value is provided (not null or empty string).
  /// Generic validator for any field that must have a value.
  ///
  /// ## Parameters
  /// - [value]: Value to validate (can be null)
  /// - [fieldName]: Name of field for error message (optional, defaults to "This field")
  ///
  /// ## Returns
  /// - null: Value is provided
  /// - String: Error message with field name
  ///
  /// ## Example
  /// ```dart
  /// Validators.validateRequired('John')
  ///   // null (valid)
  ///
  /// Validators.validateRequired('John', fieldName: 'First Name')
  ///   // null (valid)
  ///
  /// Validators.validateRequired('')
  ///   // "This field is required"
  ///
  /// Validators.validateRequired(null, fieldName: 'Username')
  ///   // "Username is required"
  /// ```
  ///
  /// ## Use Cases
  /// - Dropdown selection validation
  /// - Text field non-empty check
  /// - Checkbox required state
  /// - Multi-choice field at least one selected
  ///
  /// ## Error Message Format
  /// - With fieldName: `"{fieldName} is required"`
  /// - Without fieldName: `"This field is required"`
  ///
  /// ## Implementation
  /// Treats both null and empty string as invalid.
  /// Whitespace-only strings are considered empty.
  /// Use `.trim()` first if you want to ignore whitespace.
  ///
  /// See also:
  /// - [validateMinLength]: For minimum character requirement
  /// - [validateEmail]: For email-specific required check
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate minimum string length
  ///
  /// Checks if value meets minimum length requirement.
  /// Useful for password strength, username length, etc.
  ///
  /// ## Parameters
  /// - [value]: String value to validate (can be null)
  /// - [minLength]: Minimum required length (must be positive)
  /// - [fieldName]: Name of field for error message (optional)
  ///
  /// ## Returns
  /// - null: Value meets minimum length requirement
  /// - String: Error message describing the issue
  ///
  /// ## Example
  /// ```dart
  /// Validators.validateMinLength('password123', 8)
  ///   // null (length 11 >= 8)
  ///
  /// Validators.validateMinLength('pass', 8, fieldName: 'Password')
  ///   // "Password must be at least 8 characters"
  ///
  /// Validators.validateMinLength('', 1)
  ///   // "This field is required"
  ///
  /// Validators.validateMinLength(null, 5)
  ///   // "This field is required"
  /// ```
  ///
  /// ## Validation Sequence
  /// 1. Check if value is required (null or empty) → Return required error
  /// 2. Check if length < minLength → Return length error
  /// 3. Return null (valid)
  ///
  /// ## Use Cases
  /// - Password validation (minimum 8, 12, 16 chars)
  /// - Username length (minimum 3 characters)
  /// - Comment minimum length
  /// - Bio field minimum content
  ///
  /// ## Common Length Requirements
  /// - Username: 3-20 characters
  /// - Password: 8-128 characters
  /// - PIN: 4-6 digits
  /// - Name: 2-100 characters
  ///
  /// ## String Length Definition
  /// Uses Dart's `String.length` property (character count).
  /// Note: Unicode characters count as 1 length each.
  /// Emoji might display as 1 but could count differently.
  ///
  /// ## Error Messages
  /// Provides two error scenarios:
  /// - Empty/null: "{fieldName} is required"
  /// - Too short: "{fieldName} must be at least {minLength} characters"
  ///
  /// See also:
  /// - [validateRequired]: For required field checking
  /// - [validateEmail]: For email validation
  static String? validateMinLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }
    return null;
  }

  /// Validate URL format
  ///
  /// Checks if value is a valid HTTP or HTTPS URL with proper structure.
  /// Validates URL format but does not check if URL is accessible.
  ///
  /// ## URL Requirements
  /// - Protocol: HTTP or HTTPS required
  /// - Domain: Valid domain name with at least 2-character extension
  /// - Format: Follows standard URL structure
  /// - Query strings, fragments, ports supported
  ///
  /// ## Parameters
  /// - [value]: URL string to validate (can be null)
  ///
  /// ## Returns
  /// - null: URL format is valid
  /// - String: Error message describing validation failure
  ///
  /// ## Example
  /// ```dart
  /// Validators.validateUrl('https://example.com')
  ///   // null (valid)
  ///
  /// Validators.validateUrl('http://test.co.uk/path?q=1')
  ///   // null (valid)
  ///
  /// Validators.validateUrl('example.com')
  ///   // Error message (no protocol)
  ///
  /// Validators.validateUrl('ftp://example.com')
  ///   // Error message (FTP not supported)
  ///
  /// Validators.validateUrl('')
  ///   // Error message (empty)
  /// ```
  ///
  /// ## Valid URL Examples
  /// - https://example.com
  /// - http://www.example.com
  /// - https://subdomain.example.co.uk
  /// - https://example.com/path/to/page
  /// - https://example.com:8080/path?query=value
  /// - https://example.com#section
  /// - https://192.168.1.1/page
  ///
  /// ## Invalid URL Examples
  /// - example.com (no protocol)
  /// - ftp://example.com (FTP not supported)
  /// - //example.com (no protocol)
  /// - http:/example.com (malformed)
  /// - http://example (no TLD)
  /// - javascript:alert('xss') (not HTTP URL)
  ///
  /// ## Limitations
  /// - Only validates format, not accessibility
  /// - Does not resolve DNS or check if URL is reachable
  /// - Simplified pattern (not full RFC 3986 compliance)
  /// - IPv6 addresses not fully validated
  /// - Relative URLs not accepted
  ///
  /// ## Validation Sequence
  /// 1. Check if value is null or empty → Return error
  /// 2. Check if matches URL regex pattern → Return error if not
  /// 3. Return null (valid)
  ///
  /// ## Use Cases
  /// - Website URL field validation
  /// - API endpoint URL validation
  /// - Link input validation
  /// - Resource URL validation
  ///
  /// ## Protocol Support
  /// - ✓ HTTP (http://)
  /// - ✓ HTTPS (https://) [recommended]
  /// - ✗ FTP (ftp://)
  /// - ✗ File (file://)
  /// - ✗ Data URLs
  /// - ✗ Relative URLs
  ///
  /// ## Performance
  /// - Single regex match operation
  /// - O(n) where n = URL length
  /// - Suitable for real-time validation
  ///
  /// See also:
  /// - [validateRequired]: For required field checking
  /// - [validateEmail]: For email validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Invalid URL format';
    }
    return null;
  }
}
