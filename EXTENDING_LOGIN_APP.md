# Extending the Beautiful Login App

This guide shows how to extend the TaskManager Pro app with additional features.

## Adding a New Screen

### Example: Add a "Create Task" Screen

1. **Add screen definition to screens.json:**

```json
"createTask": {
  "type": "Scaffold",
  "properties": {
    "backgroundColor": "#F8F9FA"
  },
  "children": [
    {
      "type": "AppBar",
      "properties": {
        "title": "Create New Task",
        "centerTitle": true,
        "backgroundColor": "#6366F1",
        "elevation": 0
      }
    },
    {
      "type": "SingleChildScrollView",
      "properties": {},
      "children": [
        {
          "type": "Container",
          "properties": {
            "padding": {"all": 24}
          },
          "children": [
            {
              "type": "Column",
              "properties": {
                "crossAxisAlignment": "stretch"
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Task Title",
                    "fontSize": 14,
                    "fontWeight": "bold",
                    "color": "#1F2937"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 8}
                },
                {
                  "type": "TextField",
                  "properties": {
                    "label": "Enter task title",
                    "fieldId": "taskTitle"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 20}
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "Description",
                    "fontSize": 14,
                    "fontWeight": "bold",
                    "color": "#1F2937"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 8}
                },
                {
                  "type": "TextField",
                  "properties": {
                    "label": "Enter task description",
                    "fieldId": "taskDescription",
                    "maxLines": 4
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 20}
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "Priority",
                    "fontSize": 14,
                    "fontWeight": "bold",
                    "color": "#1F2937"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 8}
                },
                {
                  "type": "DropdownButton",
                  "properties": {
                    "hint": "Select priority",
                    "fieldId": "priority"
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 32}
                },
                {
                  "type": "ElevatedButton",
                  "properties": {
                    "label": "Create Task",
                    "backgroundColor": "#6366F1",
                    "events": {
                      "onPressed": {
                        "action": "navigate",
                        "screen": "dashboard"
                      }
                    }
                  }
                },
                {
                  "type": "SizedBox",
                  "properties": {"height": 12}
                },
                {
                  "type": "OutlinedButton",
                  "properties": {
                    "label": "Cancel",
                    "events": {
                      "onPressed": {
                        "action": "navigate",
                        "screen": "dashboard"
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
  ]
}
```

2. **Add navigation button to dashboard:**

Update the dashboard to include:

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Create New Task",
    "backgroundColor": "#6366F1",
    "events": {
      "onPressed": {
        "action": "navigate",
        "screen": "createTask"
      }
    }
  }
}
```

## Customizing Colors

### Change Primary Color

In `screens.json`, update the theme:

```json
"theme": {
  "primaryColor": "#EC4899",  // Pink instead of Indigo
  "backgroundColor": "#F8F9FA"
}
```

All primary color references will automatically update:
- AppBar backgrounds
- Button colors
- Icon colors
- Text highlights

### Add Dark Mode Support

Extend the theme:

```json
"theme": {
  "primaryColor": "#6366F1",
  "backgroundColor": "#F8F9FA",
  "brightness": "light",
  "darkMode": {
    "primaryColor": "#818CF8",
    "backgroundColor": "#111827",
    "brightness": "dark"
  }
}
```

## Adding Form Validation

### Email Validation Example

```json
{
  "type": "TextField",
  "properties": {
    "label": "Email",
    "fieldId": "email",
    "validation": {
      "type": "email",
      "message": "Please enter a valid email"
    }
  }
}
```

### Required Field Validation

```json
{
  "type": "TextField",
  "properties": {
    "label": "Username",
    "fieldId": "username",
    "validation": {
      "type": "required",
      "message": "Username is required",
      "minLength": 3
    }
  }
}
```

## API Integration

### Login with Real API

```json
{
  "type": "ElevatedButton",
  "properties": {
    "label": "Login",
    "events": {
      "onPressed": {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/auth/login",
        "data": {
          "username": "${fields.username}",
          "password": "${fields.password}"
        },
        "onSuccess": {
          "action": "navigateWithData",
          "screen": "dashboard",
          "data": {
            "username": "${response.user.name}",
            "token": "${response.token}"
          }
        },
        "onError": {
          "action": "showError",
          "message": "${error.message}"
        }
      }
    }
  }
}
```

## Adding Animations

### Animated Welcome Card

```json
{
  "type": "AnimatedContainerCustom",
  "properties": {
    "duration": 500,
    "backgroundColor": "#FFFFFF"
  },
  "children": [
    {
      "type": "Text",
      "properties": {
        "text": "Hi ${navigationData.username}! 👋"
      }
    }
  ]
}
```

### Fade In Animation

```json
{
  "type": "FadeAnimation",
  "properties": {
    "duration": 1000,
    "delay": 200
  },
  "children": [
    {
      "type": "Container",
      "properties": {
        "padding": {"all": 24}
      }
    }
  ]
}
```

## Creating a Task List Screen

```json
"tasks": {
  "type": "Scaffold",
  "children": [
    {
      "type": "AppBar",
      "properties": {
        "title": "My Tasks"
      }
    },
    {
      "type": "ListView",
      "properties": {
        "shrinkWrap": true
      },
      "children": [
        {
          "type": "ListTile",
          "properties": {
            "title": "Complete project proposal",
            "subtitle": "Due: Oct 31",
            "leadingIcon": "check_circle"
          }
        },
        {
          "type": "ListTile",
          "properties": {
            "title": "Review team feedback",
            "subtitle": "Due: Nov 2",
            "leadingIcon": "assignment"
          }
        },
        {
          "type": "ListTile",
          "properties": {
            "title": "Fix bugs in production",
            "subtitle": "Due: Oct 30",
            "leadingIcon": "error"
          }
        }
      ]
    }
  ]
}
```

## Adding Settings Screen

```json
"settings": {
  "type": "Scaffold",
  "children": [
    {
      "type": "AppBar",
      "properties": {"title": "Settings"}
    },
    {
      "type": "ListView",
      "children": [
        {
          "type": "SwitchListTile",
          "properties": {
            "title": "Dark Mode",
            "value": false,
            "fieldId": "darkMode"
          }
        },
        {
          "type": "SwitchListTile",
          "properties": {
            "title": "Notifications",
            "value": true,
            "fieldId": "notifications"
          }
        },
        {
          "type": "SwitchListTile",
          "properties": {
            "title": "Email Reminders",
            "value": true,
            "fieldId": "emailReminders"
          }
        }
      ]
    }
  ]
}
```

## Navigation Hierarchy

### Create a Tab-Based Layout

```json
{
  "type": "DefaultTabController",
  "properties": {
    "length": 3
  },
  "children": [
    {
      "type": "Scaffold",
      "children": [
        {
          "type": "AppBar",
          "properties": {
            "title": "Tasks"
          },
          "children": [
            {
              "type": "TabBar",
              "properties": {
                "tabs": [
                  {"label": "All"},
                  {"label": "Completed"},
                  {"label": "Overdue"}
                ]
              }
            }
          ]
        }
      ]
    }
  ]
}
```

## Reusable Components Pattern

### Define a Stat Card Template

```json
"components": {
  "statCard": {
    "type": "Container",
    "properties": {
      "padding": {"all": 16},
      "color": "#FFFFFF",
      "decoration": {
        "borderRadius": 12,
        "boxShadow": [{"blurRadius": 4}]
      }
    },
    "children": [
      {
        "type": "Column",
        "properties": {"crossAxisAlignment": "center"},
        "children": [
          {
            "type": "Icon",
            "properties": {
              "icon": "${icon}",
              "size": 32
            }
          },
          {
            "type": "Text",
            "properties": {
              "text": "${count}",
              "fontSize": 24,
              "fontWeight": "bold"
            }
          },
          {
            "type": "Text",
            "properties": {
              "text": "${label}",
              "fontSize": 12
            }
          }
        ]
      }
    ]
  }
}
```

## Best Practices

### ✅ DO:
- Use semantic color names (primary, success, danger, warning)
- Keep JSON organized with consistent indentation
- Use fieldId for all input elements
- Document complex callback chains
- Version your screens

### ❌ DON'T:
- Embed business logic in JSON
- Hardcode values that should be dynamic
- Create deeply nested structures (max 5 levels)
- Mix multiple concerns in one widget

## Testing Your Additions

1. **Syntax Validation**: Check JSON is valid
```bash
jq '.' assets/screens.json > /dev/null && echo "Valid"
```

2. **Hot Reload**: Changes appear immediately in running app
```bash
r  # in Flutter app terminal
```

3. **Screen Navigation**: Test all transitions
4. **Data Binding**: Verify dynamic values display correctly
5. **Styling**: Check colors, spacing, shadows render properly

## Troubleshooting

### Screen Not Found
Check the screen name matches exactly in both definition and navigation action.

### Styling Not Applied
Verify JSON format for nested objects like `decoration` and `boxShadow`.

### Navigation Not Working
Ensure callback action is in `events` → `onPressed` format.

### Data Not Binding
Check variable syntax: `${navigationData.username}` or `${fields.fieldId}`

## Next Steps

1. Add more screens following this pattern
2. Implement API calls for real data
3. Add form validation
4. Create reusable component templates
5. Add animations and transitions
6. Implement state persistence

Happy building! 🚀
