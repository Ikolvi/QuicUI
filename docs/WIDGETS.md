# QuicUI Widgets Reference

Comprehensive reference for all QuicUI widgets and their JSON configurations.

## Quick Navigation

- [Layout Widgets](#layout-widgets)
- [Display Widgets](#display-widgets)
- [Input Widgets](#input-widgets)
- [Navigation Widgets](#navigation-widgets)
- [Data Binding](#data-binding)
- [Common Properties](#common-properties)

---

## Layout Widgets

### Container

A versatile widget that can have background, padding, and children.

```json
{
  "type": "Container",
  "properties": {
    "width": 200,
    "height": 100,
    "backgroundColor": "#FFFFFF",
    "borderRadius": 8,
    "padding": {"all": 16},
    "margin": {"all": 8},
    "shadow": {
      "color": "#000000",
      "offset": {"dx": 2, "dy": 2},
      "blurRadius": 4
    }
  },
  "children": [...]
}
```

### Column

Arranges children vertically.

```json
{
  "type": "Column",
  "properties": {
    "mainAxisAlignment": "center",  // start, center, end, spaceBetween, spaceAround
    "crossAxisAlignment": "center", // start, center, end, stretch
    "mainAxisSize": "max"           // max, min
  },
  "children": [...]
}
```

### Row

Arranges children horizontally.

```json
{
  "type": "Row",
  "properties": {
    "mainAxisAlignment": "center",
    "crossAxisAlignment": "center"
  },
  "children": [...]
}
```

### Padding

Adds padding around child widget.

```json
{
  "type": "Padding",
  "properties": {
    "padding": {
      "top": 16,
      "bottom": 16,
      "left": 8,
      "right": 8
    }
  },
  "children": [...]
}
```

Or use `all` for uniform padding:

```json
{
  "type": "Padding",
  "properties": {
    "padding": {"all": 16}
  },
  "children": [...]
}
```

### Center

Centers child widget.

```json
{
  "type": "Center",
  "children": [...]
}
```

### SingleChildScrollView

Makes content scrollable if it exceeds viewport.

```json
{
  "type": "SingleChildScrollView",
  "properties": {
    "scrollDirection": "vertical"  // vertical, horizontal
  },
  "children": [...]
}
```

### Stack

Layers children on top of each other.

```json
{
  "type": "Stack",
  "properties": {
    "alignment": "topLeft"
  },
  "children": [...]
}
```

### SizedBox

Creates a box with fixed or flexible dimensions.

```json
{
  "type": "SizedBox",
  "properties": {
    "width": 100,
    "height": 50
  }
}
```

### Spacer

Fills available space (useful in Row/Column).

```json
{
  "type": "Spacer",
  "properties": {
    "flex": 1
  }
}
```

### Expanded

Expands child to fill available space in Row/Column.

```json
{
  "type": "Expanded",
  "properties": {
    "flex": 1
  },
  "children": [...]
}
```

---

## Display Widgets

### Text

Displays text with styling.

```json
{
  "type": "Text",
  "properties": {
    "text": "Hello ${navigationData.username}!",
    "fontSize": 24,
    "fontWeight": "bold",        // normal, bold, w100-w900
    "color": "#333333",
    "textAlign": "center",       // left, center, right, justify
    "maxLines": 2,
    "overflow": "ellipsis",      // clip, fade, ellipsis, visible
    "letterSpacing": 1.5,
    "lineHeight": 1.2
  }
}
```

### Card

Displays content in a Material Design card.

```json
{
  "type": "Card",
  "properties": {
    "elevation": 4,
    "margin": {"all": 8},
    "borderRadius": 8,
    "backgroundColor": "#FFFFFF",
    "shadowColor": "#000000"
  },
  "children": [...]
}
```

### Divider

Horizontal line divider.

```json
{
  "type": "Divider",
  "properties": {
    "height": 16,
    "thickness": 1,
    "color": "#CCCCCC",
    "indent": 8,
    "endIndent": 8
  }
}
```

### Image

Displays an image.

```json
{
  "type": "Image",
  "properties": {
    "src": "assets/images/logo.png",
    "width": 100,
    "height": 100,
    "fit": "cover"  // fill, contain, cover, fitWidth, fitHeight, none, scaleDown
  }
}
```

### Icon

Displays an icon.

```json
{
  "type": "Icon",
  "properties": {
    "icon": "check",           // Material icon name
    "size": 24,
    "color": "#6366F1"
  }
}
```

### ListTile

Displays a list item with title, subtitle, and icons.

```json
{
  "type": "ListTile",
  "properties": {
    "title": "List Item",
    "subtitle": "Subtitle text",
    "leadingIcon": "star",
    "trailingIcon": "chevron_right"
  }
}
```

---

## Input Widgets

### TextField

Single-line text input.

```json
{
  "type": "TextField",
  "properties": {
    "fieldId": "username",
    "label": "Enter username",
    "hint": "john_doe",
    "maxLength": 20,
    "obscureText": false,
    "enabled": true,
    "borderRadius": 8
  }
}
```

### TextArea

Multi-line text input.

```json
{
  "type": "TextArea",
  "properties": {
    "fieldId": "message",
    "label": "Message",
    "hint": "Enter your message",
    "maxLines": 5,
    "minLines": 3
  }
}
```

### ElevatedButton

Primary action button.

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login",
    "backgroundColor": "#6366F1",
    "foregroundColor": "#FFFFFF",
    "padding": {"horizontal": 24, "vertical": 12}
  },
  "events": {
    "onPressed": {
      "action": "navigateWithData",
      "screen": "dashboard",
      "data": {
        "username": "${fields.username}"
      }
    }
  }
}
```

### TextButton

Secondary button (text only).

```json
{
  "type": "TextButton",
  "properties": {
    "label": "Cancel"
  },
  "events": {
    "onPressed": {
      "action": "navigate",
      "screen": "home"
    }
  }
}
```

### OutlinedButton

Button with outline style.

```json
{
  "type": "OutlinedButton",
  "properties": {
    "label": "Sign Up",
    "borderColor": "#6366F1"
  }
}
```

### Checkbox

Boolean input checkbox.

```json
{
  "type": "Checkbox",
  "properties": {
    "fieldId": "acceptTerms",
    "label": "I agree to terms",
    "value": false
  }
}
```

### Radio

Single-choice selection from group.

```json
{
  "type": "Radio",
  "properties": {
    "fieldId": "gender",
    "label": "Male",
    "value": "male",
    "groupValue": "male"
  }
}
```

### Slider

Numeric value slider.

```json
{
  "type": "Slider",
  "properties": {
    "fieldId": "age",
    "min": 0,
    "max": 100,
    "value": 25,
    "divisions": 100,
    "label": "Age"
  }
}
```

### DropdownButton

Select from predefined options.

```json
{
  "type": "DropdownButton",
  "properties": {
    "fieldId": "country",
    "items": [
      {"label": "USA", "value": "us"},
      {"label": "Canada", "value": "ca"},
      {"label": "Mexico", "value": "mx"}
    ]
  }
}
```

---

## Navigation Widgets

### Scaffold

Top-level app structure with AppBar and body.

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [...]
}
```

### AppBar

Top navigation bar.

```json
{
  "type": "AppBar",
  "properties": {
    "title": "Dashboard",
    "backgroundColor": "#6366F1",
    "foregroundColor": "#FFFFFF",
    "elevation": 4
  }
}
```

### BottomAppBar

Bottom navigation bar.

```json
{
  "type": "BottomAppBar",
  "properties": {
    "backgroundColor": "#F8F9FA",
    "elevation": 4
  },
  "children": [...]
}
```

### Drawer

Side navigation drawer.

```json
{
  "type": "Drawer",
  "children": [...]
}
```

---

## Data Binding

### DataBinding Widget

Provides elegant context for data-driven rendering. Automatically injects navigationData into child widgets.

```json
{
  "type": "DataBinding",
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "Welcome ${navigationData.username}!"
      }
    },
    {
      "type": "Text",
      "properties": {
        "text": "Login Time: ${navigationData.loginTime}"
      }
    }
  ]
}
```

**Key Features:**
- No tight coupling to rendering engine
- Automatic context propagation to children
- Supports nested widgets
- Works with all variable patterns

**Use Cases:**
- Dashboard screens showing user info
- Data display screens
- Multi-screen flows with context passing
- Clean separation of concerns

---

## Common Properties

### Colors

Colors are specified in hex format: `#RRGGBB`

```json
{
  "color": "#FF0000",           // Red
  "backgroundColor": "#00FF00", // Green
  "foregroundColor": "#0000FF"  // Blue
}
```

### Alignment

```json
{
  "mainAxisAlignment": "start|center|end|spaceBetween|spaceAround|spaceEvenly",
  "crossAxisAlignment": "start|center|end|stretch"
}
```

### Padding & Margin

Uniform:
```json
{
  "padding": {"all": 16},
  "margin": {"all": 8}
}
```

Directional:
```json
{
  "padding": {
    "top": 16,
    "bottom": 16,
    "left": 8,
    "right": 8
  }
}
```

Shortcuts:
```json
{
  "padding": {"vertical": 16, "horizontal": 8}
}
```

### Text Styling

```json
{
  "fontSize": 16,
  "fontWeight": "bold",
  "color": "#333333",
  "textAlign": "center",
  "letterSpacing": 1,
  "lineHeight": 1.5
}
```

### Shadows

```json
{
  "shadow": {
    "color": "#000000",
    "offset": {"dx": 2, "dy": 2},
    "blurRadius": 4,
    "spreadRadius": 1
  }
}
```

### Border & BorderRadius

```json
{
  "borderRadius": 8,
  "border": {
    "color": "#CCCCCC",
    "width": 1
  }
}
```

---

## Variable Patterns

### NavigationData

Access data passed during screen navigation:

```json
{
  "type": "Text",
  "properties": {
    "text": "User: ${navigationData.username}"
  }
}
```

### Field Values

Access form field values:

```json
{
  "type": "Text",
  "properties": {
    "text": "Email: ${fields.email}"
  }
}
```

### Current Time

Insert current timestamp:

```json
{
  "type": "Text",
  "properties": {
    "text": "Updated: ${navigationData.lastUpdated}"
  }
}
```

---

## Example: Complete Login Screen

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "Column",
      "properties": {
        "mainAxisAlignment": "center",
        "crossAxisAlignment": "center"
      },
      "children": [
        {
          "type": "Text",
          "properties": {
            "text": "Welcome to QuicUI",
            "fontSize": 28,
            "fontWeight": "bold",
            "color": "#1F2937"
          }
        },
        {
          "type": "SizedBox",
          "properties": {"height": 32}
        },
        {
          "type": "Container",
          "properties": {
            "width": 320,
            "padding": {"all": 24},
            "backgroundColor": "#FFFFFF",
            "borderRadius": 12,
            "shadow": {
              "color": "#000000",
              "offset": {"dx": 0, "dy": 2},
              "blurRadius": 8
            }
          },
          "children": [
            {
              "type": "TextField",
              "properties": {
                "fieldId": "username",
                "label": "Username"
              }
            },
            {
              "type": "SizedBox",
              "properties": {"height": 16}
            },
            {
              "type": "TextField",
              "properties": {
                "fieldId": "password",
                "label": "Password",
                "obscureText": true
              }
            },
            {
              "type": "SizedBox",
              "properties": {"height": 24}
            },
            {
              "type": "ElevatedButton",
              "properties": {
                "label": "Login",
                "backgroundColor": "#6366F1"
              },
              "events": {
                "onPressed": {
                  "action": "navigateWithData",
                  "screen": "dashboard",
                  "data": {
                    "username": "${fields.username}"
                  }
                }
              }
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Example: Dashboard Screen with DataBinding

```json
{
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "AppBar",
      "properties": {
        "title": "Dashboard"
      }
    },
    {
      "type": "DataBinding",
      "children": [
        {
          "type": "Column",
          "children": [
            {
              "type": "Card",
              "properties": {
                "margin": {"all": 16}
              },
              "children": [
                {
                  "type": "Padding",
                  "properties": {"padding": {"all": 16}},
                  "children": [
                    {
                      "type": "Text",
                      "properties": {
                        "text": "Hi ${navigationData.username}! 👋",
                        "fontSize": 24,
                        "fontWeight": "bold"
                      }
                    },
                    {
                      "type": "SizedBox",
                      "properties": {"height": 8}
                    },
                    {
                      "type": "Text",
                      "properties": {
                        "text": "Welcome to your dashboard",
                        "fontSize": 12,
                        "color": "#6B7280"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

---

## Related Documentation

- [Data Binding Guide](./DATA_BINDING.md)
- [Navigation System](./NAVIGATION.md)
- [Callback System](./CALLBACKS.md)
- [QuicUI README](../README.md)
