# QuicUI Callback Action System - Complete Guide with Code Examples

## Table of Contents
1. [What are Callbacks?](#what-are-callbacks)
2. [Core Concepts](#core-concepts)
3. [The 4 Generic Actions](#the-4-generic-actions)
4. [Complete Working Examples](#complete-working-examples)
5. [Step-by-Step Tutorials](#step-by-step-tutorials)
6. [Configuration Guide](#configuration-guide)
7. [Advanced Patterns](#advanced-patterns)
8. [Testing](#testing)

---

## What are Callbacks?

**Callbacks** are functions that execute when a user interacts with your UI. In QuicUI, instead of writing Dart code, you define callbacks as **JSON**, and the app automatically runs them.

### Before (Traditional Flutter Code)
```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://myserver.com/api/auth/login'),
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = 'Login failed');
      }
    } catch (e) {
      setState(() => _error = 'Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build UI...
  }
}
```

### After (QuicUI with JSON Callbacks)
```json
{
  "screens": [{
    "id": "login_screen",
    "widgets": [{
      "id": "button_login",
      "type": "ElevatedButton",
      "properties": {"label": "Login"},
      "actions": [{
        "action": "setState",
        "updates": {"loading": true}
      }, {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/auth/login",
        "body": {
          "email": "${email_input}",
          "password": "${password_input}"
        },
        "onSuccess": {
          "action": "navigate",
          "screen": "home",
          "replace": true
        },
        "onError": {
          "action": "setState",
          "updates": {"error": "Login failed"}
        }
      }, {
        "action": "setState",
        "updates": {"loading": false}
      }]
    }]
  }]
}
```

**Key Benefits:**
- ✅ No Dart code needed for common UI flows
- ✅ Reuse JSON across multiple screens
- ✅ Easy to modify without recompiling
- ✅ Automatic error handling
- ✅ Built-in action chaining

---

## Core Concepts

### 1. Event Types (How callbacks are triggered)

| Event | Triggered By | Example |
|-------|--------------|---------|
| `onPressed` | Button tap | ElevatedButton, FloatingActionButton |
| `onTap` | Widget tap | Card, Container, ListTile |
| `onLongTap` | Long press | Any interactive widget |
| `onChanged` | Input change | TextField, Checkbox, Dropdown |
| `onSubmitted` | Form submit | TextField (keyboard action) |

### 2. Action Types (What callbacks do)

**4 Generic Actions** that combine to handle any scenario:

| Action | Purpose | Example |
|--------|---------|---------|
| `navigate` | Go to another screen | Navigate to login, home, settings |
| `setState` | Update local UI state | Toggle loading, show/hide elements |
| `apiCall` | Make HTTP requests | Fetch data, submit forms, auth |
| `custom` | Custom app logic | Email validation, calculations |

### 3. Action Chaining

Actions execute **sequentially** with success/error handling:

```
Action 1 (setState: loading=true)
    ↓
Action 2 (apiCall: POST /api/login)
    ├─ onSuccess → Action 3 (navigate: home)
    └─ onError → Action 4 (setState: error=true)
```

### 4. Variable Binding

Use `${variable_name}` to reference:
- **Form inputs**: `${email_input}`, `${password_input}`
- **App state**: `${userData.name}`, `${isLoggedIn}`
- **Session data**: `${sessionToken}`, `${userId}`

---

## The 4 Generic Actions

### Action 1: Navigate

**Purpose:** Move to another screen

#### Complete Example
```json
{
  "action": "navigate",
  "screen": "home",           // Screen ID to navigate to
  "replace": true,            // Replace current screen (like login→home)
  "arguments": {              // Pass data to next screen
    "userId": 123,
    "userName": "${userData.name}"
  }
}
```

#### Real-World Scenarios

**Scenario A: Simple Navigation (Button)**
```json
{
  "id": "button_go_home",
  "type": "ElevatedButton",
  "properties": {"label": "Go to Home"},
  "actions": [{
    "action": "navigate",
    "screen": "home"
  }]
}
```

**Scenario B: Navigation after Login (with Replace)**
```json
{
  "id": "button_login",
  "type": "ElevatedButton",
  "properties": {"label": "Login"},
  "actions": [{
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/auth/login",
    "body": {"email": "${email}", "password": "${password}"},
    "onSuccess": {
      "action": "navigate",
      "screen": "home",
      "replace": true,        // Can't go back to login
      "arguments": {"isNewLogin": true}
    }
  }]
}
```

**Scenario C: Navigation with Arguments**
```json
{
  "id": "button_open_user_profile",
  "type": "ElevatedButton",
  "properties": {"label": "View Profile"},
  "actions": [{
    "action": "navigate",
    "screen": "user_profile",
    "arguments": {
      "userId": "${userId}",
      "userName": "${userData.name}",
      "email": "${userData.email}"
    }
  }]
}
```

---

### Action 2: SetState

**Purpose:** Update local UI state

#### Complete Example
```json
{
  "action": "setState",
  "updates": {
    "loading": true,           // Toggle loading state
    "error": null,             // Clear error
    "itemCount": 42,           // Update number
    "isExpanded": false        // Toggle boolean
  }
}
```

#### Real-World Scenarios

**Scenario A: Show Loading State**
```json
{
  "id": "button_refresh",
  "type": "ElevatedButton",
  "properties": {"label": "Refresh Data"},
  "actions": [{
    "action": "setState",
    "updates": {"loading": true, "error": null}
  }, {
    "action": "apiCall",
    "method": "GET",
    "endpoint": "/api/data",
    "onSuccess": {
      "action": "setState",
      "updates": {"loading": false, "data": "${response.data}"}
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Failed to load"}
    }
  }]
}
```

**Scenario B: Toggle Visibility**
```json
{
  "id": "button_toggle_menu",
  "type": "ElevatedButton",
  "properties": {"label": "Menu"},
  "actions": [{
    "action": "setState",
    "updates": {"menuOpen": "${!menuOpen}"}  // Toggle boolean
  }]
}
```

**Scenario C: Clear Form After Submit**
```json
{
  "id": "button_submit_form",
  "type": "ElevatedButton",
  "properties": {"label": "Submit"},
  "actions": [{
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/form/submit",
    "body": {"name": "${name_input}", "email": "${email_input}"},
    "onSuccess": {
      "action": "setState",
      "updates": {
        "name_input": "",           // Clear form
        "email_input": "",
        "submitted": true,
        "successMessage": "Form submitted!"
      }
    }
  }]
}
```

---

### Action 3: ApiCall

**Purpose:** Make HTTP requests to your backend

#### Complete Example
```json
{
  "action": "apiCall",
  "method": "POST",                    // GET, POST, PUT, DELETE, PATCH
  "endpoint": "/api/auth/login",       // Server path (without base URL)
  "headers": {                         // Optional custom headers
    "Authorization": "Bearer ${token}",
    "Content-Type": "application/json"
  },
  "body": {                            // Request body (for POST/PUT/PATCH)
    "email": "${email_input}",
    "password": "${password_input}"
  },
  "onSuccess": {                       // What to do if request succeeds
    "action": "setState",
    "updates": {"user": "${response.data}"}
  },
  "onError": {                         // What to do if request fails
    "action": "setState",
    "updates": {"error": "${response.error}"}
  }
}
```

#### How Base URL Works

**Step 1: Configure Base URL in Your Flutter App**

```dart
// In your main.dart or app initialization
void main() {
  // Set the base URL for all API calls
  ApiConfig.baseUrl = 'https://myserver.com';
  // Example: https://api.example.com or http://localhost:8080
  
  runApp(QuicUI());
}
```

**Step 2: Define Endpoints in JSON**

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/auth/login"
  // This becomes: https://myserver.com + /api/auth/login
  // = https://myserver.com/api/auth/login
}
```

#### Real-World Scenarios

**Scenario A: Simple GET Request**
```json
{
  "id": "button_load_users",
  "type": "ElevatedButton",
  "properties": {"label": "Load Users"},
  "actions": [{
    "action": "setState",
    "updates": {"loading": true}
  }, {
    "action": "apiCall",
    "method": "GET",
    "endpoint": "/api/users",              // No body for GET
    "onSuccess": {
      "action": "setState",
      "updates": {
        "loading": false,
        "users": "${response.data}",       // Store response
        "userCount": "${response.data.length}"
      }
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Failed to load users"}
    }
  }]
}
```

**Scenario B: POST with Form Data (Login)**
```json
{
  "id": "button_login",
  "type": "ElevatedButton",
  "properties": {"label": "Login"},
  "actions": [{
    "action": "setState",
    "updates": {"loading": true, "error": null}
  }, {
    "action": "apiCall",
    "method": "POST",
    "endpoint": "/api/auth/login",
    "body": {
      "email": "${email_input}",
      "password": "${password_input}"
    },
    "onSuccess": {
      "action": "setState",
      "updates": {
        "loading": false,
        "sessionToken": "${response.data.token}",  // Save token
        "userId": "${response.data.userId}"
      }
    },
    "onError": {
      "action": "setState",
      "updates": {
        "loading": false,
        "error": "Invalid email or password"
      }
    }
  }, {
    "action": "navigate",
    "screen": "home",
    "replace": true
  }]
}
```

**Scenario C: PUT Request with Headers**
```json
{
  "id": "button_update_profile",
  "type": "ElevatedButton",
  "properties": {"label": "Update Profile"},
  "actions": [{
    "action": "apiCall",
    "method": "PUT",
    "endpoint": "/api/user/profile",
    "headers": {
      "Authorization": "Bearer ${sessionToken}",  // Include auth token
      "Content-Type": "application/json"
    },
    "body": {
      "name": "${name_input}",
      "phone": "${phone_input}",
      "bio": "${bio_input}"
    },
    "onSuccess": {
      "action": "setState",
      "updates": {
        "userData": "${response.data}",
        "successMessage": "Profile updated!"
      }
    },
    "onError": {
      "action": "setState",
      "updates": {"error": "Failed to update profile"}
    }
  }]
}
```

**Scenario D: DELETE Request**
```json
{
  "id": "button_delete_account",
  "type": "ElevatedButton",
  "properties": {"label": "Delete Account"},
  "actions": [{
    "action": "setState",
    "updates": {"loading": true}
  }, {
    "action": "apiCall",
    "method": "DELETE",
    "endpoint": "/api/user/account",
    "headers": {
      "Authorization": "Bearer ${sessionToken}"
    },
    "onSuccess": {
      "action": "setState",
      "updates": {"loading": false}
    },
    "onError": {
      "action": "setState",
      "updates": {"loading": false, "error": "Cannot delete account"}
    }
  }, {
    "action": "navigate",
    "screen": "login",
    "replace": true
  }]
}
```

---

### Action 4: Custom

**Purpose:** Execute custom app-specific logic

#### Complete Example
```json
{
  "action": "custom",
  "handler": "validateEmail",          // Name of custom handler
  "parameters": {
    "email": "${email_input}",
    "checkExists": true
  },
  "onSuccess": {
    "action": "setState",
    "updates": {"emailValid": true}
  },
  "onError": {
    "action": "setState",
    "updates": {"error": "Email format invalid"}
  }
}
```

#### How to Define Custom Handlers

**Step 1: Create Custom Handler in Dart**

```dart
// In your app's custom_callbacks.dart
import 'package:quicui/quicui.dart';

void registerCustomCallbacks() {
  // Register handler for email validation
  CallbackRegistry.register('validateEmail', (context, params) async {
    final email = params['email'] as String;
    
    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      throw Exception('Invalid email format');
    }
    
    // Optional: Check if email exists in database
    if (params['checkExists'] == true) {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/check-email'),
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode != 200) {
        throw Exception('Email already registered');
      }
    }
    
    return {'valid': true, 'email': email};
  });

  // Register handler for password strength check
  CallbackRegistry.register('validatePassword', (context, params) async {
    final password = params['password'] as String;
    
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw Exception('Password must contain uppercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw Exception('Password must contain number');
    }
    
    return {'valid': true, 'strength': 'strong'};
  });

  // Register handler for form validation
  CallbackRegistry.register('validateRegistrationForm', (context, params) async {
    final errors = <String>[];
    
    if ((params['name'] as String).isEmpty) {
      errors.add('Name required');
    }
    if ((params['email'] as String).isEmpty) {
      errors.add('Email required');
    }
    if ((params['password'] as String).isEmpty) {
      errors.add('Password required');
    }
    if (params['password'] != params['confirmPassword']) {
      errors.add('Passwords do not match');
    }
    
    if (errors.isNotEmpty) {
      throw Exception(errors.join(', '));
    }
    
    return {'valid': true};
  });

  // Register handler for calculations
  CallbackRegistry.register('calculateTotal', (context, params) async {
    final items = params['items'] as List;
    double total = 0;
    for (var item in items) {
      total += item['price'] * item['quantity'];
    }
    return {'total': total, 'formattedTotal': '\$${total.toStringAsFixed(2)}'};
  });
}

// Call this in main() before running the app
void main() {
  registerCustomCallbacks();
  runApp(QuicUI());
}
```

#### Real-World Scenarios

**Scenario A: Email Validation**
```json
{
  "id": "textfield_email",
  "type": "TextField",
  "properties": {"label": "Email", "hintText": "your@email.com"},
  "events": [{
    "event": "onChanged",
    "actions": [{
      "action": "custom",
      "handler": "validateEmail",
      "parameters": {
        "email": "${email_input}",
        "checkExists": false
      },
      "onSuccess": {
        "action": "setState",
        "updates": {"emailError": null}
      },
      "onError": {
        "action": "setState",
        "updates": {"emailError": "${response.error}"}
      }
    }]
  }]
}
```

**Scenario B: Password Validation**
```json
{
  "id": "textfield_password",
  "type": "TextField",
  "properties": {"label": "Password", "obscureText": true},
  "events": [{
    "event": "onChanged",
    "actions": [{
      "action": "custom",
      "handler": "validatePassword",
      "parameters": {"password": "${password_input}"},
      "onSuccess": {
        "action": "setState",
        "updates": {
          "passwordValid": true,
          "passwordStrength": "${response.data.strength}"
        }
      },
      "onError": {
        "action": "setState",
        "updates": {"passwordError": "${response.error}"}
      }
    }]
  }]
}
```

**Scenario C: Complete Form Validation Before Submit**
```json
{
  "id": "button_register",
  "type": "ElevatedButton",
  "properties": {"label": "Create Account"},
  "actions": [{
    "action": "custom",
    "handler": "validateRegistrationForm",
    "parameters": {
      "name": "${name_input}",
      "email": "${email_input}",
      "password": "${password_input}",
      "confirmPassword": "${confirmPassword_input}"
    },
    "onSuccess": [{
      "action": "setState",
      "updates": {"loading": true, "error": null}
    }, {
      "action": "apiCall",
      "method": "POST",
      "endpoint": "/api/auth/register",
      "body": {
        "name": "${name_input}",
        "email": "${email_input}",
        "password": "${password_input}"
      },
      "onSuccess": {
        "action": "navigate",
        "screen": "email_verification",
        "arguments": {"email": "${email_input}"}
      },
      "onError": {
        "action": "setState",
        "updates": {"error": "${response.error}"}
      }
    }],
    "onError": {
      "action": "setState",
      "updates": {"error": "${response.error}"}
    }
  }]
}
```

---

## Complete Working Examples

### Example 1: Login Screen (Complete)

**File:** `example/login_complete.json`

```json
{
  "version": "1.0",
  "metadata": {
    "name": "Login Screen",
    "description": "Complete login example with callbacks"
  },
  "theme": {
    "primaryColor": "#2196F3",
    "backgroundColor": "#F5F5F5",
    "textColor": "#212121"
  },
  "screens": [{
    "id": "login_screen",
    "name": "Login",
    "widgets": [{
      "id": "scaffold_login",
      "type": "Scaffold",
      "children": [{
        "id": "appbar_login",
        "type": "AppBar",
        "slot": "appBar",
        "properties": {
          "title": "Login",
          "backgroundColor": "#2196F3"
        }
      }, {
        "id": "column_form",
        "type": "Column",
        "slot": "body",
        "properties": {
          "mainAxisAlignment": "center",
          "crossAxisAlignment": "stretch"
        },
        "children": [{
          "id": "padding_form",
          "type": "Padding",
          "properties": {"padding": 24},
          "children": [{
            "id": "column_inputs",
            "type": "Column",
            "properties": {"mainAxisAlignment": "start"},
            "children": [
              {
                "id": "text_title",
                "type": "Text",
                "properties": {
                  "data": "Welcome Back",
                  "style": {"fontSize": 28, "fontWeight": "bold"}
                }
              },
              {
                "id": "text_subtitle",
                "type": "Text",
                "properties": {
                  "data": "Enter your credentials to continue",
                  "style": {"fontSize": 14, "color": "#757575"}
                },
                "margin": {"top": 8, "bottom": 32}
              },
              {
                "id": "textfield_email",
                "type": "TextField",
                "properties": {
                  "label": "Email",
                  "hintText": "your@email.com"
                },
                "stateBinding": {
                  "variable": "email_input",
                  "defaultValue": ""
                },
                "margin": {"bottom": 16},
                "events": [{
                  "event": "onChanged",
                  "actions": [{
                    "action": "setState",
                    "updates": {"emailError": null}
                  }]
                }]
              },
              {
                "id": "textfield_email_error",
                "type": "Text",
                "properties": {
                  "data": "${emailError}",
                  "style": {"fontSize": 12, "color": "#D32F2F"}
                },
                "stateBinding": {
                  "variable": "emailError",
                  "defaultValue": null
                },
                "visible": "${emailError != null}",
                "margin": {"bottom": 16}
              },
              {
                "id": "textfield_password",
                "type": "TextField",
                "properties": {
                  "label": "Password",
                  "obscureText": true
                },
                "stateBinding": {
                  "variable": "password_input",
                  "defaultValue": ""
                },
                "margin": {"bottom": 16},
                "events": [{
                  "event": "onChanged",
                  "actions": [{
                    "action": "setState",
                    "updates": {"passwordError": null}
                  }]
                }]
              },
              {
                "id": "textfield_password_error",
                "type": "Text",
                "properties": {
                  "data": "${passwordError}",
                  "style": {"fontSize": 12, "color": "#D32F2F"}
                },
                "stateBinding": {
                  "variable": "passwordError",
                  "defaultValue": null
                },
                "visible": "${passwordError != null}",
                "margin": {"bottom": 24}
              },
              {
                "id": "button_login",
                "type": "ElevatedButton",
                "properties": {
                  "label": "${isLoading ? 'Logging in...' : 'Login'}",
                  "backgroundColor": "#2196F3",
                  "textColor": "#FFFFFF"
                },
                "stateBinding": {
                  "variable": "isLoading",
                  "defaultValue": false
                },
                "enabled": "${!isLoading}",
                "actions": [{
                  "action": "setState",
                  "updates": {"isLoading": true, "error": null}
                }, {
                  "action": "apiCall",
                  "method": "POST",
                  "endpoint": "/api/auth/login",
                  "body": {
                    "email": "${email_input}",
                    "password": "${password_input}"
                  },
                  "onSuccess": {
                    "action": "setState",
                    "updates": {
                      "isLoading": false,
                      "sessionToken": "${response.data.token}",
                      "userId": "${response.data.userId}"
                    }
                  },
                  "onError": {
                    "action": "setState",
                    "updates": {
                      "isLoading": false,
                      "error": "${response.error}"
                    }
                  }
                }, {
                  "action": "navigate",
                  "screen": "home",
                  "replace": true
                }],
                "margin": {"bottom": 16}
              },
              {
                "id": "text_error_message",
                "type": "Text",
                "properties": {
                  "data": "${error}",
                  "style": {"fontSize": 14, "color": "#D32F2F", "fontWeight": "bold"}
                },
                "stateBinding": {
                  "variable": "error",
                  "defaultValue": null
                },
                "visible": "${error != null}",
                "margin": {"bottom": 16}
              },
              {
                "id": "row_signup",
                "type": "Row",
                "properties": {"mainAxisAlignment": "center"},
                "children": [{
                  "id": "text_no_account",
                  "type": "Text",
                  "properties": {
                    "data": "Don't have an account? ",
                    "style": {"fontSize": 14, "color": "#757575"}
                  }
                }, {
                  "id": "button_signup",
                  "type": "TextButton",
                  "properties": {
                    "label": "Sign Up",
                    "textColor": "#2196F3"
                  },
                  "actions": [{
                    "action": "navigate",
                    "screen": "signup"
                  }]
                }]
              }
            ]
          }]
        }]
      }]
    }]
  }]
}
```

**To use this example:**

1. **Save the JSON** to your project
2. **Configure base URL** in your Flutter app:
   ```dart
   void main() {
     ApiConfig.baseUrl = 'https://your-backend.com';
     runApp(QuicUI());
   }
   ```
3. **Create backend endpoint** `/api/auth/login`:
   ```dart
   // Backend (Node.js/Express example)
   app.post('/api/auth/login', (req, res) => {
     const { email, password } = req.body;
     
     // Validate credentials (simplified)
     if (email === 'user@example.com' && password === 'password123') {
       res.json({
         token: 'eyJhbGc...',  // JWT token
         userId: 42
       });
     } else {
       res.status(401).json({ error: 'Invalid credentials' });
     }
   });
   ```

---

### Example 2: Registration with Validation (Complete)

**File:** `example/registration_complete.json`

```json
{
  "version": "1.0",
  "metadata": {
    "name": "Registration Screen",
    "description": "Complete registration with validation callbacks"
  },
  "theme": {
    "primaryColor": "#4CAF50",
    "backgroundColor": "#F5F5F5"
  },
  "screens": [{
    "id": "signup_screen",
    "name": "Sign Up",
    "widgets": [{
      "id": "scaffold_signup",
      "type": "Scaffold",
      "children": [{
        "id": "appbar_signup",
        "type": "AppBar",
        "slot": "appBar",
        "properties": {
          "title": "Create Account",
          "backgroundColor": "#4CAF50"
        }
      }, {
        "id": "listview_form",
        "type": "ListView",
        "slot": "body",
        "properties": {"padding": 24},
        "children": [{
          "id": "column_form",
          "type": "Column",
          "children": [
            {
              "id": "textfield_name",
              "type": "TextField",
              "properties": {
                "label": "Full Name",
                "hintText": "John Doe"
              },
              "stateBinding": {
                "variable": "name_input",
                "defaultValue": ""
              },
              "margin": {"bottom": 16}
            },
            {
              "id": "textfield_email",
              "type": "TextField",
              "properties": {
                "label": "Email",
                "hintText": "your@email.com"
              },
              "stateBinding": {
                "variable": "email_input",
                "defaultValue": ""
              },
              "margin": {"bottom": 4},
              "events": [{
                "event": "onChanged",
                "actions": [{
                  "action": "custom",
                  "handler": "validateEmail",
                  "parameters": {
                    "email": "${email_input}"
                  },
                  "onSuccess": {
                    "action": "setState",
                    "updates": {"emailError": null}
                  },
                  "onError": {
                    "action": "setState",
                    "updates": {"emailError": "${response.error}"}
                  }
                }]
              }]
            },
            {
              "id": "text_email_error",
              "type": "Text",
              "properties": {
                "data": "${emailError}",
                "style": {"fontSize": 12, "color": "#D32F2F"}
              },
              "stateBinding": {
                "variable": "emailError",
                "defaultValue": null
              },
              "visible": "${emailError != null}",
              "margin": {"bottom": 16}
            },
            {
              "id": "textfield_password",
              "type": "TextField",
              "properties": {
                "label": "Password",
                "obscureText": true
              },
              "stateBinding": {
                "variable": "password_input",
                "defaultValue": ""
              },
              "margin": {"bottom": 4},
              "events": [{
                "event": "onChanged",
                "actions": [{
                  "action": "custom",
                  "handler": "validatePassword",
                  "parameters": {"password": "${password_input}"},
                  "onSuccess": {
                    "action": "setState",
                    "updates": {
                      "passwordError": null,
                      "passwordStrength": "${response.data.strength}"
                    }
                  },
                  "onError": {
                    "action": "setState",
                    "updates": {"passwordError": "${response.error}"}
                  }
                }]
              }]
            },
            {
              "id": "text_password_error",
              "type": "Text",
              "properties": {
                "data": "${passwordError}",
                "style": {"fontSize": 12, "color": "#D32F2F"}
              },
              "stateBinding": {
                "variable": "passwordError",
                "defaultValue": null
              },
              "visible": "${passwordError != null}",
              "margin": {"bottom": 16}
            },
            {
              "id": "textfield_confirm_password",
              "type": "TextField",
              "properties": {
                "label": "Confirm Password",
                "obscureText": true
              },
              "stateBinding": {
                "variable": "confirmPassword_input",
                "defaultValue": ""
              },
              "margin": {"bottom": 16},
              "events": [{
                "event": "onChanged",
                "actions": [{
                  "action": "setState",
                  "updates": {"passwordsMatch": "${password_input == confirmPassword_input}"}
                }]
              }]
            },
            {
              "id": "checkbox_terms",
              "type": "Checkbox",
              "properties": {
                "label": "I agree to Terms and Conditions"
              },
              "stateBinding": {
                "variable": "agreedToTerms",
                "defaultValue": false
              },
              "margin": {"bottom": 24}
            },
            {
              "id": "button_signup",
              "type": "ElevatedButton",
              "properties": {
                "label": "${isLoading ? 'Creating Account...' : 'Sign Up'}",
                "backgroundColor": "#4CAF50"
              },
              "stateBinding": {
                "variable": "isLoading",
                "defaultValue": false
              },
              "enabled": "${agreedToTerms && passwordsMatch && !isLoading}",
              "actions": [{
                "action": "custom",
                "handler": "validateRegistrationForm",
                "parameters": {
                  "name": "${name_input}",
                  "email": "${email_input}",
                  "password": "${password_input}",
                  "confirmPassword": "${confirmPassword_input}"
                },
                "onSuccess": [{
                  "action": "setState",
                  "updates": {"isLoading": true, "error": null}
                }, {
                  "action": "apiCall",
                  "method": "POST",
                  "endpoint": "/api/auth/register",
                  "body": {
                    "name": "${name_input}",
                    "email": "${email_input}",
                    "password": "${password_input}"
                  },
                  "onSuccess": {
                    "action": "navigate",
                    "screen": "email_verification",
                    "arguments": {"email": "${email_input}"}
                  },
                  "onError": {
                    "action": "setState",
                    "updates": {
                      "isLoading": false,
                      "error": "${response.error}"
                    }
                  }
                }],
                "onError": {
                  "action": "setState",
                  "updates": {"error": "${response.error}"}
                }
              }],
              "margin": {"bottom": 16}
            },
            {
              "id": "text_error",
              "type": "Text",
              "properties": {
                "data": "${error}",
                "style": {"fontSize": 14, "color": "#D32F2F"}
              },
              "stateBinding": {
                "variable": "error",
                "defaultValue": null
              },
              "visible": "${error != null}"
            }
          ]
        }]
      }]
    }]
  }]
}
```

---

### Example 3: Data List with CRUD Operations (Complete)

**File:** `example/data_list_complete.json`

```json
{
  "version": "1.0",
  "metadata": {
    "name": "Data List with CRUD",
    "description": "List items with delete, edit capabilities"
  },
  "theme": {
    "primaryColor": "#FF9800",
    "backgroundColor": "#FFF3E0"
  },
  "screens": [{
    "id": "items_list_screen",
    "name": "Items",
    "widgets": [{
      "id": "scaffold_list",
      "type": "Scaffold",
      "children": [{
        "id": "appbar",
        "type": "AppBar",
        "slot": "appBar",
        "properties": {
          "title": "My Items",
          "backgroundColor": "#FF9800"
        }
      }, {
        "id": "column_main",
        "type": "Column",
        "slot": "body",
        "children": [{
          "id": "container_refresh",
          "type": "Container",
          "properties": {"padding": 16},
          "children": [{
            "id": "button_refresh",
            "type": "ElevatedButton",
            "properties": {
              "label": "${isLoading ? 'Loading...' : 'Refresh'}",
              "backgroundColor": "#FF9800"
            },
            "stateBinding": {
              "variable": "isLoading",
              "defaultValue": false
            },
            "enabled": "${!isLoading}",
            "actions": [{
              "action": "setState",
              "updates": {"isLoading": true, "error": null}
            }, {
              "action": "apiCall",
              "method": "GET",
              "endpoint": "/api/items",
              "headers": {
                "Authorization": "Bearer ${sessionToken}"
              },
              "onSuccess": {
                "action": "setState",
                "updates": {
                  "isLoading": false,
                  "items": "${response.data}",
                  "itemCount": "${response.data.length}"
                }
              },
              "onError": {
                "action": "setState",
                "updates": {
                  "isLoading": false,
                  "error": "Failed to load items"
                }
              }
            }]
          }]
        }, {
          "id": "listview_items",
          "type": "ListView",
          "properties": {
            "padding": 8
          },
          "stateBinding": {
            "variable": "items",
            "defaultValue": []
          },
          "children": [{
            "id": "card_item",
            "type": "Card",
            "properties": {
              "margin": 8,
              "padding": 16
            },
            "children": [{
              "id": "row_item_content",
              "type": "Row",
              "properties": {"mainAxisAlignment": "spaceBetween"},
              "children": [{
                "id": "column_item_info",
                "type": "Column",
                "properties": {"mainAxisAlignment": "start"},
                "children": [{
                  "id": "text_item_name",
                  "type": "Text",
                  "properties": {
                    "data": "${item.name}",
                    "style": {"fontSize": 16, "fontWeight": "bold"}
                  }
                }, {
                  "id": "text_item_description",
                  "type": "Text",
                  "properties": {
                    "data": "${item.description}",
                    "style": {"fontSize": 14, "color": "#666666"}
                  }
                }]
              }, {
                "id": "row_actions",
                "type": "Row",
                "children": [{
                  "id": "button_edit",
                  "type": "IconButton",
                  "properties": {"icon": "edit"},
                  "actions": [{
                    "action": "navigate",
                    "screen": "edit_item",
                    "arguments": {"itemId": "${item.id}"}
                  }]
                }, {
                  "id": "button_delete",
                  "type": "IconButton",
                  "properties": {"icon": "delete"},
                  "actions": [{
                    "action": "setState",
                    "updates": {"deletingId": "${item.id}"}
                  }, {
                    "action": "apiCall",
                    "method": "DELETE",
                    "endpoint": "/api/items/${item.id}",
                    "headers": {
                      "Authorization": "Bearer ${sessionToken}"
                    },
                    "onSuccess": {
                      "action": "setState",
                      "updates": {
                        "deletingId": null,
                        "items": "${items.where(i => i.id != item.id).toList()}"
                      }
                    },
                    "onError": {
                      "action": "setState",
                      "updates": {
                        "deletingId": null,
                        "error": "Failed to delete item"
                      }
                    }
                  }]
                }]
              }]
            }]
          }]
        }]
      }, {
        "id": "fab_add",
        "type": "FloatingActionButton",
        "slot": "floatingActionButton",
        "properties": {
          "icon": "add",
          "backgroundColor": "#FF9800"
        },
        "actions": [{
          "action": "navigate",
          "screen": "add_item"
        }]
      }]
    }]
  }]
}
```

---

## Step-by-Step Tutorials

### Tutorial 1: Build a Todo App

**Step 1: Create the JSON file** (`example/todo_app.json`)

```json
{
  "version": "1.0",
  "screens": [{
    "id": "todo_screen",
    "widgets": [{
      "id": "scaffold",
      "type": "Scaffold",
      "children": [{
        "id": "appbar",
        "type": "AppBar",
        "slot": "appBar",
        "properties": {
          "title": "My Todos",
          "backgroundColor": "#2196F3"
        }
      }, {
        "id": "column",
        "type": "Column",
        "slot": "body",
        "children": [{
          "id": "padding_input",
          "type": "Padding",
          "properties": {"padding": 16},
          "children": [{
            "id": "row_input",
            "type": "Row",
            "children": [{
              "id": "textfield_todo",
              "type": "TextField",
              "properties": {
                "label": "What to do?",
                "hintText": "Enter a todo..."
              },
              "stateBinding": {
                "variable": "todoInput",
                "defaultValue": ""
              }
            }, {
              "id": "button_add",
              "type": "IconButton",
              "properties": {"icon": "add"},
              "actions": [{
                "action": "setState",
                "updates": {
                  "todos": "${todos.concat([{id: Date.now(), text: todoInput, done: false}])}",
                  "todoInput": ""
                }
              }]
            }]
          }]
        }, {
          "id": "listview_todos",
          "type": "ListView",
          "stateBinding": {
            "variable": "todos",
            "defaultValue": []
          },
          "children": [{
            "id": "card_todo",
            "type": "Card",
            "children": [{
              "id": "listile_todo",
              "type": "ListTile",
              "properties": {
                "title": "${todo.text}",
                "leading": "checkbox"
              },
              "actions": [{
                "action": "setState",
                "updates": {
                  "todos": "${todos.map(t => t.id === todo.id ? {...t, done: !t.done} : t).toList()}"
                }
              }]
            }]
          }]
        }]
      }]
    }]
  }]
}
```

**Step 2: Register custom handler** (in your Flutter app)

```dart
void main() {
  CallbackRegistry.register('addTodo', (context, params) async {
    final text = params['text'] as String;
    if (text.isEmpty) throw Exception('Todo cannot be empty');
    return {'id': DateTime.now().millisecondsSinceEpoch, 'text': text, 'done': false};
  });
  
  runApp(QuicUI());
}
```

**Step 3: Run your app!**

---

## Configuration Guide

### Configure Base URL

**Option 1: Hardcoded (Simple Projects)**

```dart
// main.dart
void main() {
  ApiConfig.baseUrl = 'https://api.example.com';
  runApp(QuicUI());
}
```

**Option 2: Environment Variables (Production)**

```dart
// main.dart
void main() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'development');
  
  if (env == 'production') {
    ApiConfig.baseUrl = 'https://api.example.com';
  } else if (env == 'staging') {
    ApiConfig.baseUrl = 'https://staging-api.example.com';
  } else {
    ApiConfig.baseUrl = 'http://localhost:8080';
  }
  
  runApp(QuicUI());
}
```

### Configure Authentication

**Store Token After Login**

```json
{
  "action": "apiCall",
  "method": "POST",
  "endpoint": "/api/auth/login",
  "body": {"email": "${email}", "password": "${password}"},
  "onSuccess": {
    "action": "setState",
    "updates": {
      "sessionToken": "${response.data.token}",
      "userId": "${response.data.userId}"
    }
  }
}
```

**Use Token in Headers**

```json
{
  "action": "apiCall",
  "method": "GET",
  "endpoint": "/api/user/profile",
  "headers": {
    "Authorization": "Bearer ${sessionToken}"
  }
}
```

---

## Advanced Patterns

### Pattern 1: Request/Response with Loading State

```json
{
  "actions": [
    {
      "action": "setState",
      "updates": {"loading": true, "error": null}
    },
    {
      "action": "apiCall",
      "method": "GET",
      "endpoint": "/api/data",
      "onSuccess": {
        "action": "setState",
        "updates": {"loading": false, "data": "${response.data}"}
      },
      "onError": {
        "action": "setState",
        "updates": {"loading": false, "error": "${response.error}"}
      }
    }
  ]
}
```

### Pattern 2: Form Validation

```json
{
  "actions": [
    {
      "action": "custom",
      "handler": "validateForm",
      "parameters": {
        "email": "${email_input}",
        "password": "${password_input}"
      },
      "onSuccess": [{
        "action": "setState",
        "updates": {"errors": null}
      }, {
        "action": "apiCall",
        "method": "POST",
        "endpoint": "/api/submit"
      }],
      "onError": {
        "action": "setState",
        "updates": {"errors": "${response.error}"}
      }
    }
  ]
}
```

### Pattern 3: Conditional Navigation

```json
{
  "actions": [
    {
      "action": "apiCall",
      "method": "GET",
      "endpoint": "/api/user/status",
      "onSuccess": {
        "action": "navigate",
        "screen": "${response.data.isVerified ? 'home' : 'verify_email'}"
      }
    }
  ]
}
```

---

## Testing

### Unit Test Example

```dart
void main() {
  group('ApiCall Action', () {
    test('POST with body serializes correctly', () {
      final action = ApiCallAction(
        method: 'POST',
        endpoint: '/api/login',
        body: {'email': 'test@example.com', 'password': 'pass123'},
      );

      final json = action.toJson();
      expect(json['action'], 'apiCall');
      expect(json['method'], 'POST');
      expect(json['endpoint'], '/api/login');
      expect(json['body']['email'], 'test@example.com');
    });

    test('JSON parsing creates correct action', () {
      final json = {
        'action': 'apiCall',
        'method': 'GET',
        'endpoint': '/api/users',
      };

      final action = Action.fromJson(json) as ApiCallAction;
      expect(action.method, 'GET');
      expect(action.endpoint, '/api/users');
    });
  });
}
```

---

## Summary

### Key Takeaways

1. **Callbacks** = Functions that run when user interacts with UI
2. **JSON-based** = No Dart code needed for common flows
3. **4 Action Types** = navigate, setState, apiCall, custom
4. **Action Chaining** = Actions run sequentially with success/error handling
5. **Variable Binding** = Use `${variable}` to reference form inputs and state

### Common Use Cases

- ✅ Login/Registration forms
- ✅ List with CRUD operations
- ✅ Data fetching with loading states
- ✅ Form validation
- ✅ Navigation flows
- ✅ Offline-first apps with sync
- ✅ Multi-step workflows

### Next Steps

1. Copy an example to your project
2. Configure base URL
3. Create backend endpoint
4. Test in your app
5. Add custom handlers as needed

**Happy building! 🚀**
