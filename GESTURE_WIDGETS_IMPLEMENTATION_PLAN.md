# QuicUI: Gesture & Interactive Widgets Implementation Plan

## Overview
Add gesture-based and interactive widgets to enhance user interaction capabilities. This includes GestureDetector, InkWell, and related widgets that enable custom tap, swipe, long-press, and other gesture handling.

---

## Phase 1: Core Gesture Widgets (Priority: HIGH)

### 1.1 GestureDetector
**Purpose**: Detect user gestures on child widgets  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- `child`: Widget (required)
- `onTap`: Callback function
- `onDoubleTap`: Callback function
- `onLongPress`: Callback function
- `onVerticalDragStart`: Callback function
- `onVerticalDragUpdate`: Callback function
- `onVerticalDragEnd`: Callback function
- `onHorizontalDragStart`: Callback function
- `onHorizontalDragUpdate`: Callback function
- `onHorizontalDragEnd`: Callback function
- `onPanStart`: Callback function
- `onPanUpdate`: Callback function
- `onPanEnd`: Callback function
- `behavior`: HitTestBehavior ('opaque', 'translucent', 'deferToChild')
- `excludeFromSemantics`: bool (default: false)

**JSON Example**:
```json
{
  "type": "GestureDetector",
  "properties": {
    "behavior": "opaque",
    "excludeFromSemantics": false
  },
  "children": [{
    "type": "Container",
    "properties": {
      "color": "#2196F3",
      "width": 100,
      "height": 100
    }
  }],
  "events": {
    "onTap": { "action": "navigateToScreen", "screenId": "details" },
    "onDoubleTap": { "action": "executeCallback", "callbackName": "onDoubleTapAction" },
    "onLongPress": { "action": "executeCallback", "callbackName": "onLongPressAction" }
  }
}
```

---

### 1.2 InkWell
**Purpose**: Material design tap response with splash effect  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- `child`: Widget (required)
- `onTap`: Callback function
- `onDoubleTap`: Callback function
- `onLongPress`: Callback function
- `splashColor`: Color (default: Theme.of(context).splashColor)
- `highlightColor`: Color (default: Theme.of(context).highlightColor)
- `hoverColor`: Color
- `focusColor`: Color
- `splashFactory`: InteractiveInkFeatureFactory ('default', 'splash', 'ripple')
- `radius`: double (splash radius)
- `borderRadius`: BorderRadius
- `enableFeedback`: bool (default: true)
- `excludeFromSemantics`: bool (default: false)

**JSON Example**:
```json
{
  "type": "InkWell",
  "properties": {
    "splashColor": "#FF0000",
    "highlightColor": "#FF9999",
    "radius": 20,
    "enableFeedback": true
  },
  "children": [{
    "type": "Padding",
    "properties": { "padding": "16" },
    "children": [{
      "type": "Text",
      "properties": { "text": "Tap me" }
    }]
  }],
  "events": {
    "onTap": { "action": "navigateToScreen", "screenId": "home" }
  }
}
```

---

### 1.3 InkResponse
**Purpose**: Interactive tap response with custom visual feedback  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- `child`: Widget (required)
- `onTap`: Callback function
- `onDoubleTap`: Callback function
- `onLongPress`: Callback function
- `highlightColor`: Color
- `splashColor`: Color
- `radius`: double
- `borderRadius`: BorderRadius
- `enableFeedback`: bool
- `focusColor`: Color
- `hoverColor`: Color

---

## Phase 2: Advanced Gesture Widgets (Priority: MEDIUM)

### 2.1 LongPressDraggable
**Purpose**: Long press to drag and drop items  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- `child`: Widget (required)
- `feedback`: Widget (shown while dragging)
- `data`: dynamic (drag data)
- `childWhenDragging`: Widget (shown when dragging)
- `onDragStarted`: Callback
- `onDraggableCanceled`: Callback
- `onDragEnd`: Callback
- `onDragCompleted`: Callback
- `axis`: Axis ('horizontal', 'vertical', 'free')
- `maxSimultaneousDrags`: int

---

### 2.2 DragTarget
**Purpose**: Widget that accepts dragged items  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- `builder`: Function (builds widget based on drag state)
- `onWillAccept`: Function (accepts drop)
- `onAccept`: Function (processes drop)
- `onLeave`: Function (called when drag leaves)
- `onMove`: Function (called during drag)

---

### 2.3 Draggable
**Purpose**: General purpose draggable widget  
**Status**: ❌ NOT IMPLEMENTED

**Properties to Support**:
- Similar to LongPressDraggable but triggered on simple drag

---

## Phase 3: Scrolling Gesture Widgets (Priority: MEDIUM)

### 3.1 GestureDetector with Scroll Integration
**Purpose**: Combine gestures with scroll behavior  
**Status**: ❌ PARTIAL (ScrollingWidgets exist but not integrated with GestureDetector)

---

## Phase 4: Advanced Interactions (Priority: LOW)

### 4.1 MultiTouchGestureDetector
**Purpose**: Support multi-touch gestures (pinch, rotate, scale)  
**Status**: ❌ NOT IMPLEMENTED

### 4.2 SwipeDetector
**Purpose**: Detect swipe gestures (left, right, up, down)  
**Status**: ❌ NOT IMPLEMENTED

### 4.3 RotationGestureDetector
**Purpose**: Detect rotation gestures  
**Status**: ❌ NOT IMPLEMENTED

---

## Implementation Strategy

### Step 1: Core Gesture Utilities
1. Create `lib/src/rendering/gesture_widgets.dart`
2. Implement gesture event handling helpers
3. Create callback routing for gesture events

### Step 2: Widget Implementation
For each widget:
1. Add widget builder method in `gesture_widgets.dart`
2. Add case in `_renderWidgetByType` switch statement
3. Implement property parsing
4. Support event/callback routing
5. Handle child widget rendering

### Step 3: Integration with Existing System
1. Ensure gestures work with callback system
2. Support navigation actions from gestures
3. Integrate with event system (onTap, onLongPress, etc.)
4. Support data passing through gesture events

### Step 4: Documentation & Examples
1. Update widget documentation
2. Create example JSON configs
3. Add test cases

---

## Dependencies & Considerations

### Flutter Built-in Support
- ✅ GestureDetector - native Flutter
- ✅ InkWell - Material package
- ✅ InkResponse - Material package
- ✅ Draggable/DragTarget - native Flutter
- ✅ LongPressDraggable - native Flutter

### Callback Integration
- Must route gesture callbacks through existing `_handleCallback` system
- Must support `onNavigateTo`, `onFlowNavigate`, `onExecuteCallback` from gestures
- Must pass gesture data (position, velocity, etc.) to callbacks

### State Management
- Consider state preservation during gestures
- Handle gesture cancellation properly
- Support gesture feedback (haptic, visual)

---

## Detailed Implementation Plan

### Implementation Order (Recommended)
1. **GestureDetector** (foundation for others)
2. **InkWell** (common Material pattern)
3. **InkResponse** (variant of InkWell)
4. **LongPressDraggable + DragTarget** (drag & drop)
5. **SwipeDetector** (common gesture)
6. **MultiTouch gestures** (advanced features)

### File Structure
```
lib/src/rendering/
├── gesture_widgets.dart          (NEW - all gesture widgets)
├── ui_renderer.dart              (UPDATE - add gesture widget cases)
└── gesture_helpers.dart          (NEW - gesture utilities)
```

### Key Methods to Implement
```dart
// In gesture_widgets.dart
static Widget buildGestureDetector(Map<String, dynamic> properties, ...)
static Widget buildInkWell(Map<String, dynamic> properties, ...)
static Widget buildInkResponse(Map<String, dynamic> properties, ...)
static Widget buildLongPressDraggable(Map<String, dynamic> properties, ...)
static Widget buildDragTarget(Map<String, dynamic> properties, ...)
static Widget buildSwipeDetector(Map<String, dynamic> properties, ...)

// Gesture helpers
static HitTestBehavior parseHitTestBehavior(String value)
static void handleGestureTap(Map<String, dynamic> properties, ...)
static void handleGestureLongPress(Map<String, dynamic> properties, ...)
```

---

## Testing Strategy

### Unit Tests
- Test property parsing for each widget
- Test callback routing
- Test gesture event detection

### Integration Tests
- Test GestureDetector with callback navigation
- Test InkWell with visual feedback
- Test drag & drop functionality
- Test multi-gesture scenarios

### JSON Configuration Tests
- Valid gesture widget configs
- Invalid property handling
- Callback event routing

---

## Example JSON Configurations

### GestureDetector - Simple Tap
```json
{
  "type": "GestureDetector",
  "properties": { "behavior": "opaque" },
  "events": {
    "onTap": { "action": "navigateToScreen", "screenId": "details" }
  },
  "children": [{
    "type": "Text",
    "properties": { "text": "Tap here" }
  }]
}
```

### InkWell - Material Feedback
```json
{
  "type": "InkWell",
  "properties": {
    "splashColor": "#2196F3",
    "radius": 16,
    "enableFeedback": true
  },
  "events": {
    "onTap": { "action": "executeCallback", "callbackName": "handleTap" },
    "onLongPress": { "action": "executeCallback", "callbackName": "handleLongPress" }
  },
  "children": [{
    "type": "Container",
    "properties": { "padding": "16", "color": "#E3F2FD" },
    "children": [{
      "type": "Text",
      "properties": { "text": "Press me" }
    }]
  }]
}
```

### Draggable & DragTarget
```json
{
  "type": "Column",
  "children": [
    {
      "type": "LongPressDraggable",
      "properties": {
        "data": "item1",
        "axis": "vertical"
      },
      "children": [{
        "type": "Card",
        "children": [{
          "type": "Text",
          "properties": { "text": "Drag me" }
        }]
      }]
    },
    {
      "type": "DragTarget",
      "properties": { "acceptedTypes": ["item1", "item2"] },
      "events": {
        "onAccept": { "action": "executeCallback", "callbackName": "handleDrop" }
      }
    }
  ]
}
```

---

## Success Criteria

✅ All gesture widgets render correctly  
✅ Tap, double-tap, long-press gestures work  
✅ Swipe gestures detected and routed  
✅ Drag & drop functionality works  
✅ Callbacks properly route to flow manager  
✅ Navigation works from gesture events  
✅ Visual feedback displays correctly  
✅ No duplicate widgets with existing implementations  
✅ Full backward compatibility maintained  

---

## Timeline Estimate

- **Phase 1 (Core Gestures)**: 2-3 days
- **Phase 2 (Advanced Gestures)**: 2 days
- **Phase 3 (Scroll Integration)**: 1 day
- **Phase 4 (Advanced Multi-touch)**: 2-3 days
- **Testing & Documentation**: 2 days

**Total**: ~10-12 days

---

## Notes

- Ensure all gesture callbacks integrate with existing `_handleCallback` system
- GestureDetector should be the foundation for other gesture widgets
- Consider performance implications of multiple simultaneous gestures
- Maintain consistency with Material Design patterns (InkWell, InkResponse)
- Test on both Android and iOS for platform-specific gesture behaviors
