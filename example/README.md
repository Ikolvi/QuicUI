# QuicUI Example Applications

This directory contains 5 comprehensive example applications demonstrating different QuicUI capabilities.

## Examples Overview

### 1. Counter App ⏱️
**Location:** `1_counter_app/`
- **Purpose**: Simple state management
- **Key Features**:
  - State binding to widgets
  - Event handling
  - Button interactions
  - Dynamic text updates
- **Files**: 
  - `counter_app.json` - App configuration
  - `README.md` - Detailed guide
- **Test Coverage**: 10 tests
- **Complexity**: ⭐ Beginner

### 2. Form App 📝
**Location:** `2_form_app/`
- **Purpose**: Form input and submission
- **Key Features**:
  - Text field inputs
  - Multiple keyboard types
  - Form validation
  - API submission
  - ScrollView for responsive layout
- **Files**:
  - `form_app.json` - App configuration
  - `README.md` - Detailed guide
- **Test Coverage**: 15 tests
- **Complexity**: ⭐⭐ Intermediate

### 3. Todo App ✅
**Location:** `3_todo_app/`
- **Purpose**: CRUD operations and lists
- **Key Features**:
  - ListView with dynamic items
  - Add, update, delete operations
  - Item state management
  - Checkbox interactions
  - String decorations
- **Files**:
  - `todo_app.json` - App configuration
  - `README.md` - Detailed guide
- **Test Coverage**: 18 tests
- **Complexity**: ⭐⭐⭐ Advanced

### 4. Offline Sync App 🔄
**Location:** `4_offline_sync_app/`
- **Purpose**: Offline-first architecture
- **Key Features**:
  - Network connectivity detection
  - Local data persistence
  - Sync operations
  - Pending changes tracking
  - Cache management
- **Files**:
  - `offline_sync_app.json` - App configuration
  - `README.md` - Detailed guide
- **Test Coverage**: 20 tests
- **Complexity**: ⭐⭐⭐⭐ Advanced

### 5. Dashboard App 📊
**Location:** `5_dashboard_app/`
- **Purpose**: Data visualization and analytics
- **Key Features**:
  - GridView for metric cards
  - Line charts for trends
  - Summary statistics
  - Real-time data refresh
  - Responsive layouts
  - Data aggregation
- **Files**:
  - `dashboard_app.json` - App configuration
  - `README.md` - Detailed guide
- **Test Coverage**: 22 tests
- **Complexity**: ⭐⭐⭐⭐⭐ Expert

## Quick Start

### Running Examples
```bash
# Counter App
flutter run --dart-define=QUICUI_CONFIG=examples/1_counter_app/counter_app.json

# Form App
flutter run --dart-define=QUICUI_CONFIG=examples/2_form_app/form_app.json

# Todo App
flutter run --dart-define=QUICUI_CONFIG=examples/3_todo_app/todo_app.json

# Offline Sync App
flutter run --dart-define=QUICUI_CONFIG=examples/4_offline_sync_app/offline_sync_app.json

# Dashboard App
flutter run --dart-define=QUICUI_CONFIG=examples/5_dashboard_app/dashboard_app.json
```

### Running Tests
```bash
# All example tests
flutter test test/examples/

# Specific example tests
flutter test test/examples/counter_app_test.dart
flutter test test/examples/form_app_test.dart
flutter test test/examples/todo_app_test.dart
flutter test test/examples/offline_sync_app_test.dart
flutter test test/examples/dashboard_app_test.dart
```

## Learning Path

1. **Start with Counter App** - Learn basic state management
2. **Move to Form App** - Learn form input and validation
3. **Try Todo App** - Learn list rendering and CRUD
4. **Explore Offline Sync** - Learn offline-first patterns
5. **Master Dashboard** - Learn advanced visualization

## Key Concepts Demonstrated

### State Management
- State binding to widgets
- State updates on actions
- Dynamic content

### User Input
- Text fields with validation
- Keyboard types
- Password fields
- Form submission

### List Operations
- ListView rendering
- ItemBuilder templates
- CRUD operations on lists
- Item state management

### Offline Capabilities
- Network detection
- Local persistence
- Sync queues
- Conflict resolution

### Data Visualization
- Metric cards in grids
- Line charts
- Summary statistics
- Real-time updates

## File Structure

```
examples/
├── 1_counter_app/
│   ├── counter_app.json
│   └── README.md
├── 2_form_app/
│   ├── form_app.json
│   └── README.md
├── 3_todo_app/
│   ├── todo_app.json
│   └── README.md
├── 4_offline_sync_app/
│   ├── offline_sync_app.json
│   └── README.md
├── 5_dashboard_app/
│   ├── dashboard_app.json
│   └── README.md
└── README.md (this file)
```

## Features Covered Across Examples

| Feature | Counter | Form | Todo | Offline | Dashboard |
|---------|---------|------|------|---------|-----------|
| State Binding | ✅ | ✅ | ✅ | ✅ | ✅ |
| Text Fields | ❌ | ✅ | ⚠️ | ❌ | ❌ |
| Buttons | ✅ | ✅ | ✅ | ✅ | ✅ |
| Lists | ❌ | ❌ | ✅ | ❌ | ✅ |
| Cards | ❌ | ❌ | ✅ | ✅ | ✅ |
| Charts | ❌ | ❌ | ❌ | ❌ | ✅ |
| Offline Sync | ❌ | ❌ | ❌ | ✅ | ❌ |
| API Integration | ❌ | ✅ | ❌ | ✅ | ✅ |
| ScrollView | ❌ | ✅ | ❌ | ✅ | ✅ |
| GridView | ❌ | ❌ | ❌ | ❌ | ✅ |

## Testing Summary

| App | Unit Tests | Widget Tests | Integration Tests | Total |
|-----|-----------|-------------|------------------|-------|
| Counter | 3 | 4 | 3 | 10 |
| Form | 4 | 6 | 5 | 15 |
| Todo | 5 | 7 | 6 | 18 |
| Offline | 6 | 7 | 7 | 20 |
| Dashboard | 6 | 10 | 6 | 22 |
| **TOTAL** | **24** | **34** | **27** | **85** |

## Documentation

Each example includes:
- ✅ Complete JSON configuration
- ✅ Detailed README with key concepts
- ✅ API integration examples (where applicable)
- ✅ Testing patterns
- ✅ Running instructions
- ✅ Next steps for enhancement

## Extending Examples

### Add New Sections
1. Copy an existing example directory
2. Modify the JSON configuration
3. Update the README
4. Add test files

### Modify Existing Examples
1. Edit the JSON configuration file
2. Test changes with `flutter run`
3. Update tests if needed

## Troubleshooting

### JSON Parse Errors
- Validate JSON syntax with online validators
- Check for missing commas or brackets
- Verify widget types are supported

### Widget Not Rendering
- Check widget type spelling
- Verify slot names (appBar, body, floatingActionButton)
- Check property names and types

### Tests Failing
- Run with verbose flag: `flutter test -v`
- Check widget IDs match state bindings
- Verify test mocks are set up correctly

## Advanced Topics

- Nested widget hierarchies
- Complex state management
- Custom animations
- Performance optimization
- Error handling patterns
- Accessibility features

## Contributing

To add new examples:
1. Create new directory in examples/
2. Add JSON configuration
3. Add comprehensive README
4. Create test file in test/examples/
5. Update this README with summary
6. Submit PR with all changes

## Resources

- **QuicUI Documentation**: See `docs/` directory
- **Widget Reference**: See `lib/src/widgets/`
- **Testing Guide**: See `test/README.md`
- **Architecture**: See `ARCHITECTURE.md`

---

**Total Test Coverage:** 85 example tests  
**Last Updated:** 2024-01-01  
**Version:** 1.0.0
