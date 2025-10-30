import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Integration - Real-World Patterns', () {
    test('User registration form pattern', () {
      final json = {
        'type': 'SingleChildScrollView',
        'child': {
          'type': 'Column',
          'children': [
            {
              'type': 'Padding',
              'padding': 24,
              'child': {
                'type': 'Text',
                'text': 'Create Account',
                'style': {'fontSize': 28, 'fontWeight': 'bold'}
              }
            },
            {
              'type': 'Padding',
              'padding': 24,
              'child': {
                'type': 'Column',
                'children': [
                  {
                    'type': 'TextField',
                    'label': 'Full Name',
                    'hintText': 'John Doe'
                  },
                  {'type': 'SizedBox', 'height': 16},
                  {
                    'type': 'TextField',
                    'label': 'Email',
                    'hintText': 'john@example.com',
                    'keyboardType': 'emailAddress'
                  },
                  {'type': 'SizedBox', 'height': 16},
                  {
                    'type': 'TextField',
                    'label': 'Password',
                    'obscureText': true
                  },
                  {'type': 'SizedBox', 'height': 24},
                  {'type': 'ElevatedButton', 'label': 'Sign Up'},
                  {'type': 'SizedBox', 'height': 16},
                  {
                    'type': 'Row',
                    'mainAxisAlignment': 'center',
                    'children': [
                      {'type': 'Text', 'text': 'Already have an account? '},
                      {
                        'type': 'TextButton',
                        'label': 'Sign In'
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<SingleChildScrollView>());
    });

    test('Dashboard with grid layout and cards', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Container',
            'color': '#0066CC',
            'padding': 16,
            'child': {
              'type': 'Text',
              'text': 'Dashboard',
              'style': {'fontSize': 24, 'fontWeight': 'bold', 'color': '#FFFFFF'}
            }
          },
          {
            'type': 'Padding',
            'padding': 16,
            'child': {
              'type': 'GridView.count',
              'crossAxisCount': 2,
              'mainAxisSpacing': 16,
              'crossAxisSpacing': 16,
              'children': [
                {
                  'type': 'Card',
                  'child': {
                    'type': 'Padding',
                    'padding': 16,
                    'child': {
                      'type': 'Column',
                      'children': [
                        {'type': 'Text', 'text': 'Users'},
                        {'type': 'SizedBox', 'height': 8},
                        {'type': 'Text', 'text': '1,234', 'style': {'fontSize': 24, 'fontWeight': 'bold'}}
                      ]
                    }
                  }
                },
                {
                  'type': 'Card',
                  'child': {
                    'type': 'Padding',
                    'padding': 16,
                    'child': {
                      'type': 'Column',
                      'children': [
                        {'type': 'Text', 'text': 'Posts'},
                        {'type': 'SizedBox', 'height': 8},
                        {'type': 'Text', 'text': '567', 'style': {'fontSize': 24, 'fontWeight': 'bold'}}
                      ]
                    }
                  }
                },
                {
                  'type': 'Card',
                  'child': {
                    'type': 'Padding',
                    'padding': 16,
                    'child': {
                      'type': 'Column',
                      'children': [
                        {'type': 'Text', 'text': 'Likes'},
                        {'type': 'SizedBox', 'height': 8},
                        {'type': 'Text', 'text': '12K', 'style': {'fontSize': 24, 'fontWeight': 'bold'}}
                      ]
                    }
                  }
                },
                {
                  'type': 'Card',
                  'child': {
                    'type': 'Padding',
                    'padding': 16,
                    'child': {
                      'type': 'Column',
                      'children': [
                        {'type': 'Text', 'text': 'Comments'},
                        {'type': 'SizedBox', 'height': 8},
                        {'type': 'Text', 'text': '2.5K', 'style': {'fontSize': 24, 'fontWeight': 'bold'}}
                      ]
                    }
                  }
                }
              ]
            }
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('Todo list with CRUD representation', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Container',
            'color': '#F5F5F5',
            'padding': 16,
            'child': {
              'type': 'Row',
              'children': [
                {
                  'type': 'Expanded',
                  'child': {
                    'type': 'TextField',
                    'hintText': 'Add a task...'
                  }
                },
                {'type': 'SizedBox', 'width': 8},
                {'type': 'IconButton', 'icon': 'add'}
              ]
            }
          },
          {
            'type': 'Expanded',
            'child': {
              'type': 'ListView',
              'children': [
                {
                  'type': 'CheckboxListTile',
                  'title': {'type': 'Text', 'text': 'Buy groceries'},
                  'value': false
                },
                {
                  'type': 'CheckboxListTile',
                  'title': {'type': 'Text', 'text': 'Write documentation'},
                  'value': true
                },
                {
                  'type': 'CheckboxListTile',
                  'title': {'type': 'Text', 'text': 'Review pull requests'},
                  'value': false
                }
              ]
            }
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('Product card with image and pricing', () {
      final json = {
        'type': 'Card',
        'child': {
          'type': 'Column',
          'children': [
            {
              'type': 'Container',
              'height': 200,
              'color': '#E0E0E0',
              'child': {'type': 'Center', 'child': {'type': 'Text', 'text': '[Product Image]'}}
            },
            {
              'type': 'Padding',
              'padding': 16,
              'child': {
                'type': 'Column',
                'children': [
                  {'type': 'Text', 'text': 'Premium Widget', 'style': {'fontSize': 18, 'fontWeight': 'bold'}},
                  {'type': 'SizedBox', 'height': 8},
                  {'type': 'Text', 'text': 'High quality product description goes here'},
                  {'type': 'SizedBox', 'height': 12},
                  {
                    'type': 'Row',
                    'mainAxisAlignment': 'spaceBetween',
                    'children': [
                      {'type': 'Text', 'text': '\$29.99', 'style': {'fontSize': 16, 'fontWeight': 'bold'}},
                      {'type': 'ElevatedButton', 'label': 'Add to Cart'}
                    ]
                  }
                ]
              }
            }
          ]
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Card>());
    });

    test('Settings page with grouped options', () {
      final json = {
        'type': 'ListView',
        'children': [
          {
            'type': 'Container',
            'color': '#F5F5F5',
            'padding': 16,
            'child': {'type': 'Text', 'text': 'Account Settings'}
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Profile'},
            'trailing': {'type': 'Icon', 'icon': 'arrow_forward'}
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Change Password'},
            'trailing': {'type': 'Icon', 'icon': 'arrow_forward'}
          },
          {
            'type': 'Divider'
          },
          {
            'type': 'Container',
            'color': '#F5F5F5',
            'padding': 16,
            'child': {'type': 'Text', 'text': 'Preferences'}
          },
          {
            'type': 'SwitchListTile',
            'title': {'type': 'Text', 'text': 'Dark Mode'},
            'value': false
          },
          {
            'type': 'SwitchListTile',
            'title': {'type': 'Text', 'text': 'Notifications'},
            'value': true
          },
          {
            'type': 'Divider'
          },
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Logout'},
            'trailing': {'type': 'Icon', 'icon': 'exit_to_app'}
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });
  });
}
