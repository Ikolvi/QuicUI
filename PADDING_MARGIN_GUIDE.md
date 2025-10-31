# Enhanced Padding & Margin Guide

## Overview

QuicUI v1.0.5 introduces enhanced support for padding and margin properties, making it easier to create well-spaced, professional UIs with less JSON code.

## New Syntax Support

### 1. Uniform Spacing - `{"all": value}`

Apply the same spacing to all sides:

```json
{
  "type": "Container",
  "properties": {
    "padding": {"all": 16},
    "margin": {"all": 12}
  }
}
```

**Flutter equivalent:**
```dart
Container(
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(12),
)
```

### 2. Symmetric Spacing - `{"horizontal": h, "vertical": v}`

Different spacing for horizontal (left/right) and vertical (top/bottom):

```json
{
  "type": "Container", 
  "properties": {
    "padding": {"horizontal": 20, "vertical": 10},
    "margin": {"horizontal": 16, "vertical": 8}
  }
}
```

**Flutter equivalent:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
)
```

### 3. Individual Sides - `{"left": l, "right": r, "top": t, "bottom": b}`

Complete control over each side:

```json
{
  "type": "Container",
  "properties": {
    "padding": {
      "left": 36,
      "right": 20, 
      "top": 16,
      "bottom": 24
    }
  }
}
```

**Flutter equivalent:**
```dart
Container(
  padding: EdgeInsets.fromLTRB(36, 16, 20, 24),
)
```

### 4. Simple Number - Direct Value

For uniform spacing, you can still use a simple number:

```json
{
  "type": "Container",
  "properties": {
    "padding": 16,  // Same as {"all": 16}
    "margin": 8     // Same as {"all": 8}
  }
}
```

## Real-World Examples

### Task Card with Professional Spacing

```json
{
  "type": "Container",
  "properties": {
    "padding": {"all": 16},
    "margin": {"bottom": 12, "horizontal": 8},
    "decoration": {
      "color": "#FFFFFF",
      "borderRadius": {"all": 12},
      "boxShadow": [
        {
          "color": "#E0E0E0",
          "blurRadius": 8,
          "spreadRadius": 0,
          "offset": {"dx": 0, "dy": 2}
        }
      ]
    }
  },
  "children": [
    {
      "type": "Row",
      "properties": {
        "mainAxisAlignment": "space_between",
        "crossAxisAlignment": "center"
      },
      "children": [
        {
          "type": "Expanded",
          "children": [
            {
              "type": "Column",
              "properties": {
                "crossAxisAlignment": "start"
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Complete project documentation",
                    "fontSize": 16,
                    "fontWeight": "600"
                  }
                },
                {
                  "type": "Container",
                  "properties": {
                    "padding": {"horizontal": 12, "vertical": 8},
                    "margin": {"top": 8},
                    "decoration": {
                      "color": "#4CAF50",
                      "borderRadius": {"all": 8}
                    }
                  },
                  "children": [
                    {
                      "type": "Text", 
                      "properties": {
                        "text": "Due: Today, 5 PM",
                        "fontSize": 12,
                        "color": "#FFFFFF"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "Container",
          "properties": {
            "padding": {"all": 8}
          },
          "children": [
            {
              "type": "Icon",
              "properties": {
                "icon": "check_circle",
                "color": "#4CAF50",
                "size": 24
              }
            }
          ]
        }
      ]
    }
  ]
}
```

### Form with Consistent Spacing

```json
{
  "type": "Container",
  "properties": {
    "padding": {"horizontal": 24, "vertical": 32}
  },
  "children": [
    {
      "type": "Column",
      "properties": {
        "crossAxisAlignment": "stretch"
      },
      "children": [
        {
          "type": "Container",
          "properties": {
            "margin": {"bottom": 16}
          },
          "children": [
            {
              "type": "TextField",
              "properties": {
                "label": "Email",
                "hint": "Enter your email"
              }
            }
          ]
        },
        {
          "type": "Container", 
          "properties": {
            "margin": {"bottom": 24}
          },
          "children": [
            {
              "type": "TextField",
              "properties": {
                "label": "Password",
                "obscureText": true
              }
            }
          ]
        },
        {
          "type": "ElevatedButton",
          "properties": {
            "label": "Login",
            "padding": {"horizontal": 32, "vertical": 16}
          }
        }
      ]
    }
  ]
}
```

## Migration from Old Syntax

### Before (v1.0.4 and earlier)

```json
{
  "type": "Container",
  "properties": {
    "padding": {
      "left": 16,
      "right": 16, 
      "top": 16,
      "bottom": 16
    }
  }
}
```

### After (v1.0.5+) ✨

```json
{
  "type": "Container",
  "properties": {
    "padding": {"all": 16}
  }
}
```

**Result:** 75% less JSON code for common spacing patterns!

## Best Practices

### 1. Use Consistent Spacing Scale

Define a spacing scale and stick to it:

```json
// Recommended spacing values
{
  "xs": 4,    // {"all": 4}
  "sm": 8,    // {"all": 8} 
  "md": 16,   // {"all": 16}
  "lg": 24,   // {"all": 24}
  "xl": 32    // {"all": 32}
}
```

### 2. Combine Different Formats

Mix formats based on your needs:

```json
{
  "type": "Container",
  "properties": {
    "padding": {"horizontal": 20, "vertical": 16},  // Symmetric
    "margin": {"bottom": 12}                        // Individual side
  }
}
```

### 3. Use Expanded for Responsive Layout

Prevent overflow issues with proper Expanded usage:

```json
{
  "type": "Row",
  "children": [
    {
      "type": "Expanded",        // Flexible text content
      "children": [
        {
          "type": "Text",
          "properties": {"text": "Long text that might overflow"}
        }
      ]
    },
    {
      "type": "Container",       // Fixed size icon
      "properties": {
        "padding": {"all": 8}
      },
      "children": [
        {
          "type": "Icon",
          "properties": {"icon": "more_vert"}
        }
      ]
    }
  ]
}
```

## Implementation Details

The enhanced padding/margin support is implemented in the `_parseEdgeInsets` method in `ui_renderer.dart`:

```dart
static EdgeInsets? _parseEdgeInsets(dynamic value) {
  if (value == null) return null;
  if (value is num) return EdgeInsets.all(value.toDouble());
  if (value is Map) {
    // Handle "all" property for uniform padding/margin
    if (value.containsKey('all')) {
      final allValue = (value['all'] as num?)?.toDouble() ?? 0;
      return EdgeInsets.all(allValue);
    }
    
    // Handle "horizontal" and "vertical" shorthand properties
    if (value.containsKey('horizontal') || value.containsKey('vertical')) {
      final horizontal = (value['horizontal'] as num?)?.toDouble() ?? 0;
      final vertical = (value['vertical'] as num?)?.toDouble() ?? 0;
      return EdgeInsets.symmetric(
        horizontal: horizontal,
        vertical: vertical,
      );
    }
    
    // Handle individual sides (LTRB format)
    return EdgeInsets.fromLTRB(
      (value['left'] as num?)?.toDouble() ?? 0,
      (value['top'] as num?)?.toDouble() ?? 0,
      (value['right'] as num?)?.toDouble() ?? 0,
      (value['bottom'] as num?)?.toDouble() ?? 0,
    );
  }
  return null;
}
```

## Backward Compatibility

All existing syntax remains supported:

- ✅ `{"left": 10, "right": 10, "top": 10, "bottom": 10}` - Still works
- ✅ `16` - Direct number still works  
- ✅ All previous JSON structures remain valid

The new syntax is additive - no breaking changes!

## Benefits

1. **Less Code**: Up to 75% reduction in JSON for common spacing patterns
2. **Better Readability**: Clear intent with semantic property names
3. **Faster Development**: Common patterns are easier to write
4. **Mobile-Optimized**: Better support for responsive, mobile-first layouts
5. **Future-Proof**: Extensible architecture for additional spacing features

## What's Next

Future enhancements planned:
- Named spacing tokens (e.g., `"spacing": "md"`)
- Responsive spacing based on screen size
- Animation-friendly spacing transitions
- Design system integration

---

**Need help?** Check out the [Task Manager Example](./example/task_manager_runner/) for real-world usage patterns of the enhanced padding/margin system.