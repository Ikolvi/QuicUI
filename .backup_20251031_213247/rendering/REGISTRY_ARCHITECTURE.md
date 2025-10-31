# Widget Factory Registry - Modular Architecture

## Overview
The WidgetFactoryRegistry serves as a **unified registry** that delegates widget building to specialized category files. This architecture enables:

1. **Clear Separation of Concerns**: Each widget category has its own file
2. **Scalability**: Easy to add new widgets or categories
3. **Maintainability**: Widget logic is organized by type/purpose
4. **Reusability**: Widgets can be used independently or through the registry

## Architecture

```
┌─ Widget Factory Registry (Main Entry Point)
│  └─ _allWidgets: Map<String, WidgetBuilder>
│
├─ APP-LEVEL WIDGETS (app_level_widgets.dart)
│  ├─ MaterialApp
│  ├─ Scaffold
│  ├─ AppBar
│  ├─ BottomAppBar
│  ├─ Drawer
│  ├─ FloatingActionButton
│  ├─ NavigationBar
│  └─ TabBar
│
├─ GESTURE WIDGETS (gesture_widgets.dart)
│  ├─ GestureDetector
│  ├─ InkWell
│  ├─ InkResponse
│  ├─ Draggable
│  ├─ DragTarget
│  └─ ... (custom gesture widgets)
│
├─ ANIMATION WIDGETS (animation_widgets.dart)
│  ├─ AnimatedContainer
│  ├─ AnimatedOpacity
│  ├─ AnimatedScale
│  ├─ AnimatedRotation
│  └─ ... (25+ animation types)
│
├─ LAYOUT WIDGETS (layout_widgets.dart)
│  ├─ Column
│  ├─ Row
│  ├─ Container
│  ├─ Stack
│  ├─ LayoutBuilder
│  ├─ SliverAppBar
│  └─ ... (45+ layout widgets)
│
├─ INPUT WIDGETS (input_widgets.dart)
│  ├─ TextField
│  ├─ Button variants
│  ├─ Checkbox
│  ├─ Radio
│  └─ ... (form inputs)
│
├─ DISPLAY WIDGETS (display_widgets.dart)
│  ├─ Text
│  ├─ Image
│  ├─ Icon
│  ├─ Card
│  ├─ Chip
│  └─ ... (30+ display widgets)
│
├─ NAVIGATION WIDGETS (navigation_widgets.dart)
│  ├─ NavigationRail
│  ├─ Breadcrumb
│  ├─ MenuBar
│  ├─ SideBar
│  └─ ... (12+ navigation types)
│
├─ SCROLLING WIDGETS (scrolling_widgets.dart)
│  ├─ NestedScrollView
│  ├─ CustomScrollView
│  ├─ SliverGrid
│  ├─ SliverList
│  └─ ... (10+ scrolling variants)
│
├─ DATA DISPLAY WIDGETS (data_display_widgets.dart)
│  ├─ LineChart
│  ├─ BarChart
│  ├─ DataGrid
│  └─ ... (12+ data display types)
│
├─ STATE MANAGEMENT WIDGETS (state_management_widgets.dart)
│  ├─ LoadingStateWidget
│  ├─ ErrorStateWidget
│  ├─ EmptyStateWidget
│  └─ ... (16 state widgets)
│
├─ FORM WIDGETS (form_widget_builders.dart)
│  ├─ Form
│  ├─ TextFormField
│  └─ ... (8 form widgets)
│
└─ DIALOG/OVERLAY (dialog_widgets.dart)
   ├─ Dialog
   ├─ AlertDialog
   └─ ... (5+ dialog types)
```

## Registry Organization

### Building Process
1. UIRenderer receives widget configuration JSON
2. Calls `WidgetFactoryRegistry.getBuilder(widgetType)` 
3. Returns appropriate builder function
4. Builder function creates and returns widget
5. Widget is placed in widget tree

### Widget Builder Signature (Unified)
```dart
typedef WidgetBuilder = Widget Function(
  Map<String, dynamic> properties,
  List<dynamic> childrenData,
  BuildContext context,
  dynamic render,
);
```

### Category Files - Builder Signatures
Each category file may have its own builder function signatures for flexibility:

#### Gesture Widgets (`gesture_widgets.dart`)
```dart
Widget buildGestureDetector(
  Map<String, dynamic> config,
  Function(dynamic, Map<String, dynamic>)? onCallback,
)
```

#### Animation Widgets (`animation_widgets.dart`)
```dart
static Widget buildAnimatedContainer(
  Map<String, dynamic> properties,
  List<dynamic> childrenData,
)
```

#### Navigation Widgets (`navigation_widgets.dart`)
```dart
static Widget buildNavigationRail(
  Map<String, dynamic> properties,
  List<dynamic>? children,
)
```

## Implementation Pattern

### In Registry (Wrapper/Adapter Methods)
```dart
// Adapter method that converts registry signature to category-specific signature
static Widget _buildGestureDetector(
  Map<String, dynamic> properties,
  List<dynamic> childrenData,
  BuildContext context,
  dynamic render,
) {
  // Convert registry signature to gesture_widgets signature
  final config = {
    'properties': properties,
    'children': childrenData,
    'events': properties['events'] ?? {},
  };
  
  return gesture_widgets_module.buildGestureDetector(
    config,
    null, // onCallback - can be injected if needed
  );
}
```

## Benefits

1. **Modularity**: Each category is independent
2. **Testability**: Individual categories can be tested separately
3. **Flexibility**: Different signature patterns can be used where optimal
4. **Maintainability**: Easy to find and update specific widget types
5. **Documentation**: Each category file can have focused documentation
6. **Scalability**: Easy to add new categories or widgets

## Registry Categories Count

| Category | File | Count | Status |
|----------|------|-------|--------|
| App-Level | app_level_widgets.dart | 8 | ✅ |
| Gesture | gesture_widgets.dart | 11+ | ✅ |
| Animation | animation_widgets.dart | 25+ | ✅ |
| Layout | layout_widgets.dart | 45+ | ✅ |
| Input | input_widgets.dart | 25+ | ✅ |
| Display | display_widgets.dart | 30+ | ✅ |
| Navigation | navigation_widgets.dart | 12+ | ✅ |
| Scrolling | scrolling_widgets.dart | 10+ | ✅ |
| Data Display | data_display_widgets.dart | 12+ | ✅ |
| State Mgmt | state_management_widgets.dart | 16+ | ✅ |
| Form | form_widget_builders.dart | 8 | ✅ |
| Dialog | dialog_widgets.dart | 5+ | ✅ |
| **TOTAL** | **13 files** | **207+** | **✅** |

## Next Steps

1. Create adapter/wrapper methods for each category
2. Update registry map to use wrapper methods
3. Test complete delegation chain
4. Document API contracts between registry and categories
5. Add error handling and logging
