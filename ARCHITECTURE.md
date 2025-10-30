# QuicUI Architecture Documentation

## Overview

QuicUI follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│      Presentation Layer (UI)             │
│  - QuicUI Widgets                        │
│  - Widget Factory                        │
│  - Rendering Engine                      │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│    Business Logic Layer                  │
│  - State Management                      │
│  - Form Management                       │
│  - Action Execution                      │
│  - Theming System                        │
└─────────────────────────────────────────┘
                    ▼
┌─────────────────────────────────────────┐
│      Data Layer                          │
│  - API Client (Dio)                      │
│  - Local Database (ObjectBox)            │
│  - Cache Management                      │
│  - Sync Mechanism                        │
└─────────────────────────────────────────┘
```

---

## Layer 1: Core Models & Serialization

### QuicWidget Model

Base model for all renderable components:

```dart
abstract class QuicWidget {
  final String type;
  final String? id;
  final Map<String, dynamic> properties;
  final QuicWidget? child;
  final List<QuicWidget>? children;
  
  const QuicWidget({
    required this.type,
    this.id,
    this.properties = const {},
    this.child,
    this.children,
  });
  
  factory QuicWidget.fromJson(Map<String, dynamic> json) => 
    _$QuicWidgetFromJson(json);
  
  Map<String, dynamic> toJson() => _$QuicWidgetToJson(this);
}
```

### Key Models

1. **Actions** - User interactions
   - NavigationAction
   - ApiAction
   - StateAction
   - AnalyticsAction
   - CustomAction

2. **Forms** - Form-related models
   - FormField
   - FormValidation
   - FormSubmission

3. **Theme** - Theming models
   - QuicTheme
   - ColorScheme
   - Typography
   - Spacing

---

## Layer 2: JSON Parsing & Validation

### JSON Parser Flow

```
Raw JSON String
    ↓
Schema Validation
    ↓
Model Mapping
    ↓
QuicWidget Tree
    ↓
Widget Factory
```

### Parser Implementation

```dart
class JsonParser {
  // Parse JSON string to QuicWidget
  static Future<QuicWidget> parse(String json) async {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      final validator = SchemaValidator();
      
      // Validate against schema
      if (!validator.validate(data)) {
        throw QuicException('Invalid schema');
      }
      
      return QuicWidget.fromJson(data);
    } catch (e) {
      throw QuicException('Parse error: $e');
    }
  }
  
  // Parse from remote URL
  static Future<QuicWidget> parseUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    return parse(response.body);
  }
}
```

---

## Layer 3: Widget System

### Widget Factory Pattern

The widget factory converts JSON to renderable Flutter widgets:

```dart
class WidgetFactory {
  static final _registry = <String, WidgetBuilder>{};
  
  // Register widget builders
  static void register(String type, WidgetBuilder builder) {
    _registry[type] = builder;
  }
  
  // Create widget from model
  static Widget createWidget(
    QuicWidget model,
    BuildContext context,
  ) {
    final builder = _registry[model.type];
    if (builder == null) {
      return _errorWidget('Unknown widget: ${model.type}');
    }
    return builder(context, model);
  }
}
```

### Example: Text Widget

```dart
class QuicText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  
  const QuicText({
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
  });
  
  factory QuicText.fromJson(
    QuicWidget widget,
    BuildContext context,
  ) {
    final props = widget.properties;
    return QuicText(
      text: props['text'] ?? '',
      fontSize: _parseDouble(props['fontSize']),
      fontWeight: _parseFontWeight(props['fontWeight']),
      color: _parseColor(props['color']),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}
```

---

## Layer 4: State Management (BLoC Pattern)

### BLoC Architecture

QuicUI uses **BLoC (Business Logic Component)** pattern with flutter_bloc for complete separation of business logic from presentation.

```dart
// ===== Events =====
abstract class QuicEvent extends Equatable {
  const QuicEvent();
  
  @override
  List<Object?> get props => [];
}

class QuicStateEvent extends QuicEvent {
  final String key;
  final dynamic value;
  
  const QuicStateEvent(this.key, this.value);
  
  @override
  List<Object?> get props => [key, value];
}

class QuicDataFetchEvent extends QuicEvent {
  final String dataKey;
  
  const QuicDataFetchEvent(this.dataKey);
  
  @override
  List<Object?> get props => [dataKey];
}

// ===== States =====
abstract class QuicBlocState extends Equatable {
  const QuicBlocState();
  
  @override
  List<Object?> get props => [];
}

class QuicInitial extends QuicBlocState {
  const QuicInitial();
}

class QuicLoading extends QuicBlocState {
  final String? message;
  
  const QuicLoading({this.message});
  
  @override
  List<Object?> get props => [message];
}

class QuicStateUpdated extends QuicBlocState {
  final Map<String, dynamic> state;
  
  const QuicStateUpdated(this.state);
  
  @override
  List<Object?> get props => [state];
}

class QuicError extends QuicBlocState {
  final String message;
  
  const QuicError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// ===== BLoC =====
class QuicBloc extends Bloc<QuicEvent, QuicBlocState> {
  final Map<String, dynamic> _state = {};
  
  QuicBloc() : super(const QuicInitial()) {
    on<QuicStateEvent>(_onStateEvent);
    on<QuicDataFetchEvent>(_onDataFetch);
  }
  
  Future<void> _onStateEvent(
    QuicStateEvent event,
    Emitter<QuicBlocState> emit,
  ) async {
    try {
      _state[event.key] = event.value;
      emit(QuicStateUpdated(Map.from(_state)));
    } catch (e) {
      emit(QuicError('Failed to update state: $e'));
    }
  }
  
  Future<void> _onDataFetch(
    QuicDataFetchEvent event,
    Emitter<QuicBlocState> emit,
  ) async {
    try {
      emit(const QuicLoading(message: 'Fetching data...'));
      // Fetch data from API/database
      emit(QuicStateUpdated(Map.from(_state)));
    } catch (e) {
      emit(QuicError('Failed to fetch data: $e'));
    }
  }
  
  dynamic getState(String key) => _state[key];
}
```

### Usage in Widgets

```dart
// In widgets - Access state
BlocBuilder<QuicBloc, QuicBlocState>(
  builder: (context, state) {
    if (state is QuicLoading) {
      return const CircularProgressIndicator();
    } else if (state is QuicStateUpdated) {
      return Text(state.state['userName'] ?? 'Guest');
    } else if (state is QuicError) {
      return Text('Error: ${state.message}');
    }
    return const SizedBox();
  },
)

// Trigger events
context.read<QuicBloc>().add(
  QuicStateEvent('userName', 'John'),
);
```

---

## Layer 5: Actions Execution

### Action Execution Flow

```
User Interaction
    ↓
Action Triggered
    ↓
ActionExecutor.execute()
    ↓
┌─────────────────────────┐
│  Action Type?           │
├─────────────────────────┤
│ - Navigation → Route    │
│ - API → HTTP Request    │
│ - State → Update State  │
│ - Analytics → Track     │
│ - Custom → Plugin       │
└─────────────────────────┘
    ↓
Action Complete
```

### Executor Implementation

```dart
class ActionExecutor {
  static Future<void> execute(
    QuicAction action,
    BuildContext context,
  ) async {
    switch (action.type) {
      case 'navigation':
        await _handleNavigation(action, context);
        break;
      case 'api':
        await _handleApi(action, context);
        break;
      case 'state':
        _handleState(action, context);
        break;
      case 'custom':
        await _handleCustom(action, context);
        break;
    }
  }
  
  static Future<void> _handleNavigation(
    QuicAction action,
    BuildContext context,
  ) async {
    final route = action.parameters['route'] as String;
    await Navigator.of(context).pushNamed(route);
  }
}
```

---

## Layer 6: Forms System (BLoC-based)

### Form State Management with BLoC

```dart
// ===== Form Events =====
abstract class FormEvent extends Equatable {
  const FormEvent();
}

class FormFieldChangedEvent extends FormEvent {
  final String fieldName;
  final dynamic value;
  
  const FormFieldChangedEvent(this.fieldName, this.value);
  
  @override
  List<Object?> get props => [fieldName, value];
}

class FormValidateEvent extends FormEvent {
  const FormValidateEvent();
  
  @override
  List<Object?> get props => [];
}

class FormSubmitEvent extends FormEvent {
  const FormSubmitEvent();
  
  @override
  List<Object?> get props => [];
}

// ===== Form States =====
abstract class FormBlocState extends Equatable {
  const FormBlocState();
}

class FormInitial extends FormBlocState {
  const FormInitial();
  
  @override
  List<Object?> get props => [];
}

class FormUpdated extends FormBlocState {
  final Map<String, dynamic> formData;
  final Map<String, List<String>> errors;
  
  const FormUpdated(this.formData, this.errors);
  
  @override
  List<Object?> get props => [formData, errors];
}

class FormValidating extends FormBlocState {
  const FormValidating();
  
  @override
  List<Object?> get props => [];
}

class FormValid extends FormBlocState {
  final Map<String, dynamic> formData;
  
  const FormValid(this.formData);
  
  @override
  List<Object?> get props => [formData];
}

class FormInvalid extends FormBlocState {
  final Map<String, List<String>> errors;
  
  const FormInvalid(this.errors);
  
  @override
  List<Object?> get props => [errors];
}

class FormSubmitting extends FormBlocState {
  const FormSubmitting();
  
  @override
  List<Object?> get props => [];
}

class FormSubmitted extends FormBlocState {
  final dynamic result;
  
  const FormSubmitted(this.result);
  
  @override
  List<Object?> get props => [result];
}

// ===== Form BLoC =====
class QuicFormBloc extends Bloc<FormEvent, FormBlocState> {
  final Map<String, dynamic> _formData = {};
  final Map<String, List<String>> _errors = {};
  final List<FormField> fields;
  
  QuicFormBloc({required this.fields}) : super(const FormInitial()) {
    on<FormFieldChangedEvent>(_onFieldChanged);
    on<FormValidateEvent>(_onValidate);
    on<FormSubmitEvent>(_onSubmit);
  }
  
  Future<void> _onFieldChanged(
    FormFieldChangedEvent event,
    Emitter<FormBlocState> emit,
  ) async {
    _formData[event.fieldName] = event.value;
    emit(FormUpdated(Map.from(_formData), Map.from(_errors)));
  }
  
  Future<void> _onValidate(
    FormValidateEvent event,
    Emitter<FormBlocState> emit,
  ) async {
    emit(const FormValidating());
    
    _errors.clear();
    
    for (final field in fields) {
      final errors = await field.validate(_formData[field.name]);
      if (errors.isNotEmpty) {
        _errors[field.name] = errors;
      }
    }
    
    if (_errors.isEmpty) {
      emit(FormValid(Map.from(_formData)));
    } else {
      emit(FormInvalid(Map.from(_errors)));
    }
  }
  
  Future<void> _onSubmit(
    FormSubmitEvent event,
    Emitter<FormBlocState> emit,
  ) async {
    try {
      emit(const FormSubmitting());
      
      // First validate
      _errors.clear();
      
      for (final field in fields) {
        final errors = await field.validate(_formData[field.name]);
        if (errors.isNotEmpty) {
          _errors[field.name] = errors;
        }
      }
      
      if (_errors.isNotEmpty) {
        emit(FormInvalid(Map.from(_errors)));
        return;
      }
      
      // Then submit
      final result = await _submitForm(Map.from(_formData));
      emit(FormSubmitted(result));
    } catch (e) {
      emit(FormInvalid({'_submit': ['$e']}));
    }
  }
  
  Future<dynamic> _submitForm(Map<String, dynamic> data) async {
    // Override in subclass or pass submitAction
    throw UnimplementedError();
  }
}
}
```

---

## Layer 7: Local Data Storage

### ObjectBox Integration

High-performance, embedded database for Flutter:

```dart
// Model definitions with ObjectBox annotations
@Entity()
class CachedUIScreen {
  @Id()
  int id = 0;
  
  late String screenId;
  late String jsonData;
  late DateTime createdAt;
  late DateTime? expiresAt;
  
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

@Entity()
class UserStateEntry {
  @Id()
  int id = 0;
  
  late String key;
  late String value;
  late DateTime updatedAt;
}

// Database provider
class ObjectBoxProvider {
  static late final ObjectBox _objectBox;
  
  static Future<void> init() async {
    _objectBox = await ObjectBox.create();
  }
  
  // Cache operations
  static Future<void> cacheUI(
    String screenId,
    String jsonData,
    Duration ttl,
  ) async {
    final screen = CachedUIScreen()
      ..screenId = screenId
      ..jsonData = jsonData
      ..createdAt = DateTime.now()
      ..expiresAt = DateTime.now().add(ttl);
    
    _objectBox.screenStore.put(screen);
  }
  
  static Future<String?> getCachedUI(String screenId) async {
    final cached = _objectBox.screenStore
      .query(CachedUIScreen_.screenId.equals(screenId))
      .build()
      .findFirst();
    
    if (cached != null && !cached.isExpired) {
      return cached.jsonData;
    }
    
    return null;
  }
  
  // State persistence
  static Future<void> setState(String key, dynamic value) async {
    final entry = UserStateEntry()
      ..key = key
      ..value = jsonEncode(value)
      ..updatedAt = DateTime.now();
    
    _objectBox.stateStore.put(entry);
  }
  
  static Future<dynamic> getState(String key) async {
    final entry = _objectBox.stateStore
      .query(UserStateEntry_.key.equals(key))
      .build()
      .findFirst();
    
    if (entry != null) {
      return jsonDecode(entry.value);
    }
    return null;
  }
}
```

### Performance Characteristics

| Operation | Time |
|-----------|------|
| Query | < 1ms |
| Insert | < 5ms |
| Update | < 5ms |
| Batch Insert (1000) | < 50ms |

---

## Layer 8: Theming System

### Dynamic Theme Management

```dart
class ThemeManager extends ChangeNotifier {
  late QuicTheme _currentTheme;
  
  QuicTheme get theme => _currentTheme;
  
  // Parse theme from JSON
  void setTheme(String themeJson) {
    final data = jsonDecode(themeJson) as Map<String, dynamic>;
    _currentTheme = QuicTheme.fromJson(data);
    notifyListeners();
  }
  
  // Get theme at runtime
  Color getColor(String token) {
    return _currentTheme.colors[token] ?? Colors.black;
  }
  
  TextStyle getTextStyle(String token) {
    return _currentTheme.typography[token] ?? const TextStyle();
  }
}
```

### Theme Application

```dart
// In Material/Cupertino app
ThemeData buildThemeData(QuicTheme quicTheme) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: quicTheme.colors['primary'] ?? Colors.blue,
      onPrimary: Colors.white,
      secondary: quicTheme.colors['secondary'] ?? Colors.pink,
      // ... more colors
    ),
    textTheme: TextTheme(
      displayLarge: quicTheme.getTextStyle('headingLarge'),
      bodyMedium: quicTheme.getTextStyle('bodyMedium'),
      // ... more styles
    ),
  );
}
```

---

## Extensibility Points

### 1. Custom Widgets

```dart
class CustomWidgetRegistry {
  static final _customWidgets = <String, WidgetBuilder>{};
  
  static void registerCustomWidget(
    String type,
    WidgetBuilder builder,
  ) {
    _customWidgets[type] = builder;
  }
  
  static Widget? buildCustomWidget(
    String type,
    QuicWidget model,
    BuildContext context,
  ) {
    return _customWidgets[type]?.call(context, model);
  }
}
```

### 2. Custom Actions

```dart
class CustomActionHandler {
  static final _handlers = <String, ActionHandler>{};
  
  static void registerAction(
    String type,
    ActionHandler handler,
  ) {
    _handlers[type] = handler;
  }
  
  static Future<void> execute(
    String type,
    QuicAction action,
    BuildContext context,
  ) async {
    return _handlers[type]?.call(action, context);
  }
}
```

### 3. Custom Validators

```dart
class ValidatorRegistry {
  static final _validators = <String, ValidatorFn>{};
  
  static void registerValidator(
    String type,
    ValidatorFn validator,
  ) {
    _validators[type] = validator;
  }
  
  static Future<List<String>> validate(
    String type,
    dynamic value,
  ) async {
    return _validators[type]?.call(value) ?? [];
  }
}
```

---

## Data Flow Diagram

```
┌──────────────────────┐
│   Remote API Server  │
└──────────────────────┘
         ▲
         │ JSON Response
         │
┌──────────────────────┐
│   API Client (Dio)   │
└──────────────────────┘
         ▲
         │ HTTP Request
         │
┌──────────────────────┐
│  Action Executor     │
└──────────────────────┘
         ▲
         │
┌──────────────────────┐
│   QuicState          │
└──────────────────────┘
    ▲             ▼
    │             │ Triggers
    │             │
    │        ┌────────────┐
    │        │ Widget     │
    └────────│ Build      │
             └────────────┘
                    ▼
             ┌──────────────────┐
             │ ObjectBox (Cache)│
             └──────────────────┘
```

---

## Performance Optimization Strategies

### 1. Lazy Loading
- Load widgets only when visible
- Use `ListView.builder` for lists
- Implement `const` constructors

### 2. Memory Management
- Dispose resources properly
- Implement `ChangeNotifier.dispose()`
- Use weak references where appropriate

### 3. Network Optimization
- Cache responses with TTL
- Implement connection pooling
- Use gzip compression

### 4. Database Optimization
- Index frequently queried fields
- Batch operations when possible
- Use transactions for atomic operations

---

## Error Handling Strategy

```dart
abstract class QuicException implements Exception {
  final String message;
  final dynamic originalError;
  
  QuicException(this.message, {this.originalError});
  
  @override
  String toString() => message;
}

class ParseException extends QuicException {
  ParseException(String message) : super('Parse Error: $message');
}

class NetworkException extends QuicException {
  NetworkException(String message) : super('Network Error: $message');
}

class ValidationException extends QuicException {
  ValidationException(String message) : super('Validation Error: $message');
}
```

---

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Parser and validator logic
- Action execution
- Form validation

### Widget Tests
- Widget rendering
- User interactions
- State updates
- Theme application

### Integration Tests
- End-to-end workflows
- Network requests
- Database operations
- Navigation flows

---

## Deployment & Versioning

### Schema Versioning

```json
{
  "version": "1.0",
  "minClientVersion": "0.1.0",
  "widgets": [...]
}
```

### Backward Compatibility

- Support multiple schema versions
- Graceful degradation
- Migration scripts for breaking changes

---

*Last Updated: October 30, 2025*
