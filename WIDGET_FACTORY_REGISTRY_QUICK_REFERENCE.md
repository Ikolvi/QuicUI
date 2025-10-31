# Widget Factory Registry - Quick Reference Guide

## Overview
The Widget Factory Registry provides centralized access to 50+ Flutter widgets organized in 8 categories.

---

## Quick Start

### Get All Widgets
```dart
final allWidgets = WidgetFactoryRegistry.getAllWidgets();
```

### Get Specific Category
```dart
final layoutWidgets = WidgetFactoryRegistry.getLayoutWidgets();
final textWidgets = WidgetFactoryRegistry.getTextWidgets();
final buttonWidgets = WidgetFactoryRegistry.getButtonWidgets();
final imageWidgets = WidgetFactoryRegistry.getImageWidgets();
final containerWidgets = WidgetFactoryRegistry.getContainerWidgets();
final formWidgets = WidgetFactoryRegistry.getFormWidgets();
final inputWidgets = WidgetFactoryRegistry.getInputWidgets();
final listWidgets = WidgetFactoryRegistry.getListWidgets();
```

### Check if Widget is Registered
```dart
if (WidgetFactoryRegistry.isRegistered('SizedBox')) {
  // Widget is available
}
```

### Get a Widget Builder
```dart
final builder = WidgetFactoryRegistry.getBuilder('ListView');
if (builder != null) {
  final widget = builder(properties, children, context, render);
}
```

---

## Widget Categories

### 1. Layout Widgets (23)
**Size Management**
- SizedBox
- AspectRatio
- FractionallySizedBox
- IntrinsicHeight
- IntrinsicWidth

**Flex Layout**
- Expanded
- Flexible
- Spacer

**Scrolling**
- SingleChildScrollView
- ListView
- GridView
- Wrap

**Visual Effects**
- Transform
- Opacity
- DecoratedBox

**Clipping**
- ClipRect
- ClipRRect
- ClipOval

**Other**
- Material
- Table

### 2. Text Widgets (2)
- Text
- RichText

### 3. Button Widgets (3)
- Button (ElevatedButton)
- IconButton
- FloatingActionButton

### 4. Image Widgets (2)
- Image
- Icon

### 5. Container Widgets (2)
- Container
- Card

### 6. Form Widgets (2)
- Form
- TextFormField

### 7. Input Widgets (5)
- TextField
- Checkbox
- Radio
- Slider
- Switch

### 8. List Widgets (3)
- ListTile
- ListView.builder
- GridView.builder

---

## Common Property Examples

### SizedBox
```dart
{
  'width': 100,
  'height': 50
}
```

### ListView
```dart
{
  'scrollDirection': 'vertical',  // or 'horizontal'
  'shrinkWrap': false
}
```

### GridView
```dart
{
  'crossAxisCount': 2,
  'shrinkWrap': false
}
```

### AspectRatio
```dart
{
  'aspectRatio': 16 / 9
}
```

### ClipRRect
```dart
{
  'radius': 12.0
}
```

### Opacity
```dart
{
  'opacity': 0.5
}
```

### Transform
```dart
{
  'offsetX': 10.0,
  'offsetY': 20.0
}
```

### DecoratedBox
```dart
{
  'decoration': {
    'color': '#FF6B6B',
    'borderRadius': {
      'all': 8.0
    },
    'border': {
      'top': {
        'color': '#000000',
        'width': 1.0
      }
    }
  }
}
```

---

## Usage Patterns

### Pattern 1: Direct Registry Access
```dart
final builder = WidgetFactoryRegistry.getBuilder('SizedBox');
if (builder != null) {
  final widget = builder(
    {'width': 100, 'height': 50},
    [],
    context,
    renderFunction,
  );
}
```

### Pattern 2: Category-Based Access
```dart
final layoutWidgets = WidgetFactoryRegistry.getLayoutWidgets();
layoutWidgets.forEach((name, builder) {
  print('Layout widget: $name');
});
```

### Pattern 3: Validation Before Build
```dart
final widgetType = 'ListView';
if (WidgetFactoryRegistry.isRegistered(widgetType)) {
  final builder = WidgetFactoryRegistry.getBuilder(widgetType);
  // Build the widget
}
```

### Pattern 4: Dynamic Widget Creation
```dart
Map<String, dynamic> config = {
  'type': 'Column',
  'properties': {
    'mainAxisAlignment': 'center',
  },
  'children': [...]
};

if (WidgetFactoryRegistry.isRegistered(config['type'])) {
  final widget = buildWidgetFromConfig(config);
}
```

---

## Builder Function Signature

```dart
typedef WidgetBuilder = Widget Function(
  Map<String, dynamic> properties,   // Widget configuration
  List<dynamic> childrenData,        // Child widget data
  BuildContext context,              // Build context
  dynamic render,                    // Render function
);
```

---

## Helper Methods Available

### In LayoutWidgets Class
- `_parseDouble(dynamic value)` → double?
- `_parseColor(String? colorString)` → Color?
- `_parseBoxDecoration(dynamic value)` → BoxDecoration?
- `_parseBorder(dynamic value)` → Border?
- `_parseBorderSide(dynamic value)` → BorderSide
- `_parseBorderRadius(dynamic value)` → BorderRadius?
- `_parseBoxShadow(dynamic value)` → List<BoxShadow>?

---

## Extending the Registry

### Adding a New Widget

1. **Add Builder to LayoutWidgets**
```dart
static Widget buildMyWidget(
  Map<String, dynamic> properties,
  List<dynamic> childrenData,
  BuildContext context,
  Widget Function(Map<String, dynamic>) render,
) {
  // Implementation
}
```

2. **Add Delegate to Registry**
```dart
static Widget _buildMyWidget(...) => 
  LayoutWidgets.buildMyWidget(...);
```

3. **Add to Registry Map**
```dart
static final Map<String, WidgetBuilder> _customWidgets = {
  'MyWidget': _buildMyWidget,
};
```

4. **Add to getAllWidgets()**
```dart
return <String, WidgetBuilder>{
  ..._layoutWidgets,
  ..._customWidgets,  // Add here
};
```

---

## Performance Tips

1. **Use Category Methods** - Faster than getAllWidgets() for specific categories
2. **Cache Registry** - Store registry reference if building many widgets
3. **Validate First** - Use isRegistered() before getBuilder()
4. **Lazy Loading** - Consider async widget building for large lists

---

## Troubleshooting

### Widget Not Found
```dart
// Check if widget is registered
if (!WidgetFactoryRegistry.isRegistered('MyWidget')) {
  print('Widget not found in registry');
}
```

### Property Parsing Issues
- Check property naming (case-sensitive)
- Verify types match expected format
- Use helper methods for complex types

### Performance Issues
- Profile registry access times
- Consider caching builder functions
- Use category methods for filtered access

---

## Common Recipes

### Create a SizedBox
```dart
final builder = WidgetFactoryRegistry.getBuilder('SizedBox')!;
final sizedBox = builder(
  {'width': 100, 'height': 50},
  [],
  context,
  (_) => Container(),
);
```

### Create a ListView
```dart
final builder = WidgetFactoryRegistry.getBuilder('ListView')!;
final listView = builder(
  {'scrollDirection': 'vertical'},
  itemsList,
  context,
  (item) => Text(item.toString()),
);
```

### Create Nested Layout
```dart
// Column > [SizedBox > ListView]
final column = LayoutWidgets.buildColumn(
  {'mainAxisAlignment': 'start'},
  [
    {
      'type': 'SizedBox',
      'properties': {'height': 100},
      'children': [...]
    },
    {
      'type': 'ListView',
      'properties': {'scrollDirection': 'vertical'},
      'children': [...]
    }
  ],
  context,
  renderFunction,
);
```

---

## API Reference

### Registry Methods
| Method | Returns | Purpose |
|--------|---------|---------|
| getAllWidgets() | Map<String, WidgetBuilder> | Get all 50+ widgets |
| getLayoutWidgets() | Map<String, WidgetBuilder> | Get layout widgets |
| getTextWidgets() | Map<String, WidgetBuilder> | Get text widgets |
| getButtonWidgets() | Map<String, WidgetBuilder> | Get button widgets |
| getImageWidgets() | Map<String, WidgetBuilder> | Get image widgets |
| getContainerWidgets() | Map<String, WidgetBuilder> | Get container widgets |
| getFormWidgets() | Map<String, WidgetBuilder> | Get form widgets |
| getInputWidgets() | Map<String, WidgetBuilder> | Get input widgets |
| getListWidgets() | Map<String, WidgetBuilder> | Get list widgets |
| isRegistered(type) | bool | Check widget availability |
| getBuilder(type) | WidgetBuilder? | Get specific builder |

---

## Notes

- Registry is immutable after initialization
- All builders return non-null Widget instances
- Properties use JSON-compatible types
- Children data can be raw maps or widget instances
- Render function handles actual widget building

---

*Last Updated: Phase 3 Part 2*  
*Widget Count: 50+*  
*Categories: 8*  
*Status: Production Ready*
