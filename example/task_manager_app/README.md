# TaskManager Pro - Pure JSON Example App

A complete, production-ready task management application built **entirely with JSON configuration**. No widget code - just pure JSON.

## Overview

TaskManager Pro showcases how to build a full-featured mobile application using only JSON configuration with QuicUI. The app features:

- **5 Complete Screens**: Tasks, Add Task, Schedule, Analytics, Settings
- **5-Tab Bottom Navigation**: Seamless navigation between features
- **100% JSON Configuration**: All UI defined in `screens.json`
- **Minimal Bootstrap**: Only 70 lines of Dart code to load and render

## Architecture

```
task_manager_app/
├── main.dart           (70 lines - bootstrap only)
├── screens.json        (1000+ lines - complete app)
└── README.md          (this file)
```

## How It Works

1. **Bootstrap** (`main.dart`):
   - Loads JSON configuration from assets
   - Renders screens through `UIRenderer`
   - Handles navigation and tab switching

2. **Configuration** (`screens.json`):
   - Defines 5 complete screens
   - Specifies all UI elements as JSON
   - Includes theme, navigation, and animations

3. **Rendering**:
   ```
   JSON Config → UIRenderer.render() → Flutter Widgets
   ```

## Features Demonstrated

### 1. **Tasks Screen** (`tasks_home`)
- Task summary with completion stats
- Task list with status indicators
- Color-coded priority levels
- Checkbox interactions

### 2. **Add Task Screen** (`add_task`)
- Complete form with multiple input types
- Text fields for title and description
- Priority selection with segmented control
- Date picker for due dates
- Dropdown for team assignment
- Submit and cancel buttons

### 3. **Schedule Screen** (`schedule`)
- Calendar widget with marked dates
- Timeline of upcoming tasks
- Date navigation controls
- Event scheduling visualization

### 4. **Analytics Screen** (`analytics`)
- Completion rate progress bar
- Priority distribution chart
- Weekly statistics display
- Visual analytics using containers

### 5. **Settings Screen** (`settings`)
- Account information display
- User preferences (notifications, dark mode)
- App version and info
- Settings switches and toggles

## Screens Breakdown

| Screen | Widgets | Data |
|--------|---------|------|
| Tasks | 25+ widgets | Task list, stats |
| Add Task | 20+ widgets | Form inputs |
| Schedule | 15+ widgets | Calendar, timeline |
| Analytics | 18+ widgets | Charts, metrics |
| Settings | 20+ widgets | User prefs |

## JSON Structure

Each screen follows this pattern:

```json
{
  "id": "unique_id",
  "name": "Screen Name",
  "type": "Scaffold",
  "properties": {},
  "children": [
    {
      "type": "AppBar",
      "properties": {
        "title": "Title",
        "backgroundColor": "#1E88E5"
      }
    },
    {
      "type": "Column",
      "properties": {},
      "children": [
        // More widgets...
      ]
    }
  ]
}
```

## Navigation

5-tab bottom navigation bar:
1. **Tasks** - Main task list
2. **Add** - Create new task
3. **Calendar** - Schedule view
4. **Analytics** - Progress tracking
5. **Settings** - User preferences

## Running the App

```bash
# From project root
flutter run

# Or specify example
flutter run -t example/task_manager_app/main.dart
```

## Customization

To modify the app, edit `screens.json`:

1. **Change theme colors**:
   ```json
   "theme": {
     "primaryColor": "#NEW_COLOR"
   }
   ```

2. **Modify screen content**:
   - Edit widget properties
   - Add/remove children
   - Update text and labels

3. **Add new screens**:
   - Add to `screens` array
   - Add to `navigation.tabs`
   - Reference in navigation

## Supported Widgets

The app uses 50+ widgets from QuicUI:

**Layout**: Container, Column, Row, Stack, SingleChildScrollView, GridView, Padding, SizedBox, Wrap

**Input**: TextField, DatePicker, DropdownButtonForm, Checkbox, Switch, Rating, SegmentedControl

**Display**: Text, Icon, ProgressBar, CircularProgress, Timeline, Calendar, Badge, Tag

**Navigation**: AppBar, BottomNavigationBar, Scaffold

**Buttons**: ElevatedButton, OutlinedButton

**State**: LoadingStateWidget, StatusBadge, InfoPanel

## Code Statistics

- **Bootstrap Code**: 70 lines (main.dart)
- **Widget Configuration**: 1000+ lines (JSON)
- **Total Screens**: 5
- **Navigation Tabs**: 5
- **Total Widgets**: 100+

## Benefits of Pure JSON Approach

✅ **No Compilation**: Update UI without rebuilding app
✅ **Easy Maintenance**: Plain text JSON is easy to understand
✅ **Version Control**: Track UI changes in git
✅ **Server-Driven**: Load configs from backend
✅ **A/B Testing**: Switch configs easily
✅ **No Widget Knowledge**: Design UIs without learning Flutter widgets

## Production Ready

This example demonstrates:
- Professional app structure
- Real-world use cases
- Complex interactions
- State management patterns
- Form handling
- Data visualization
- Navigation flows

## Next Steps

1. **Extend Screens**: Add more screens by editing JSON
2. **Connect Backend**: Load JSON from API instead of assets
3. **Add Callbacks**: Implement form submissions and actions
4. **Internationalization**: Add multi-language support
5. **Dynamic Content**: Load data from databases

## Deployment

The app is production-ready for iOS and Android:

```bash
# Build APK
flutter build apk

# Build iOS
flutter build ios

# Build Web
flutter build web
```

---

**Built with QuicUI** - Server-Driven UI Framework for Flutter
