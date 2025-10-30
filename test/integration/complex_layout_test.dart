import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';

void main() {
  group('Integration - Complex Layouts', () {
    test('Stack with 5 Positioned children renders correctly', () {
      final json = {
        'type': 'Stack',
        'children': [
          {
            'type': 'Positioned',
            'top': 10,
            'left': 10,
            'child': {'type': 'Container', 'width': 50, 'height': 50}
          },
          {
            'type': 'Positioned',
            'top': 70,
            'right': 10,
            'child': {'type': 'Container', 'width': 50, 'height': 50}
          },
          {
            'type': 'Positioned',
            'bottom': 10,
            'left': 10,
            'child': {'type': 'Container', 'width': 50, 'height': 50}
          },
          {
            'type': 'Positioned',
            'bottom': 10,
            'right': 10,
            'child': {'type': 'Container', 'width': 50, 'height': 50}
          },
          {
            'type': 'Positioned',
            'top': 50,
            'left': 50,
            'right': 50,
            'bottom': 50,
            'child': {'type': 'Center', 'child': {'type': 'Text', 'text': 'Center'}}
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Stack>());
    });

    test('Column with alternating Row and Column (5 levels deep)', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Row',
            'children': [
              {'type': 'Expanded', 'child': {'type': 'Container', 'color': '#FF0000'}},
              {'type': 'Expanded', 'child': {'type': 'Container', 'color': '#00FF00'}},
              {'type': 'Expanded', 'child': {'type': 'Container', 'color': '#0000FF'}}
            ]
          },
          {
            'type': 'Column',
            'children': [
              {
                'type': 'Row',
                'children': [
                  {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'A'}},
                  {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'B'}}
                ]
              },
              {
                'type': 'Row',
                'children': [
                  {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'C'}},
                  {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'D'}}
                ]
              }
            ]
          },
          {
            'type': 'Row',
            'children': [
              {
                'type': 'Expanded',
                'child': {
                  'type': 'Column',
                  'children': [
                    {'type': 'Text', 'text': 'Left Top'},
                    {'type': 'Text', 'text': 'Left Bottom'}
                  ]
                }
              },
              {
                'type': 'Expanded',
                'child': {
                  'type': 'Column',
                  'children': [
                    {'type': 'Text', 'text': 'Right Top'},
                    {'type': 'Text', 'text': 'Right Bottom'}
                  ]
                }
              }
            ]
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Column>());
    });

    test('GridView with complex item structure', () {
      final json = {
        'type': 'GridView.count',
        'crossAxisCount': 3,
        'children': [
          {
            'type': 'Card',
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Container', 'height': 100, 'color': '#FF5733'},
                {'type': 'Padding', 'padding': 8, 'child': {'type': 'Text', 'text': 'Item 1'}}
              ]
            }
          },
          {
            'type': 'Card',
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Container', 'height': 100, 'color': '#33FF57'},
                {'type': 'Padding', 'padding': 8, 'child': {'type': 'Text', 'text': 'Item 2'}}
              ]
            }
          },
          {
            'type': 'Card',
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Container', 'height': 100, 'color': '#3357FF'},
                {'type': 'Padding', 'padding': 8, 'child': {'type': 'Text', 'text': 'Item 3'}}
              ]
            }
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });

    test('ListView with complex nested item layouts', () {
      final json = {
        'type': 'ListView',
        'children': [
          {
            'type': 'ListTile',
            'title': {'type': 'Text', 'text': 'Item 1'},
            'subtitle': {'type': 'Text', 'text': 'Subtitle 1'}
          },
          {
            'type': 'Container',
            'padding': 16,
            'child': {
              'type': 'Column',
              'children': [
                {'type': 'Text', 'text': 'Nested item'},
                {'type': 'SizedBox', 'height': 8},
                {
                  'type': 'Row',
                  'children': [
                    {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'Left'}},
                    {'type': 'Expanded', 'child': {'type': 'Text', 'text': 'Right'}}
                  ]
                }
              ]
            }
          },
          {
            'type': 'Card',
            'child': {
              'type': 'Padding',
              'padding': 12,
              'child': {
                'type': 'Column',
                'children': [
                  {'type': 'Text', 'text': 'Card Title'},
                  {'type': 'Divider'},
                  {'type': 'Text', 'text': 'Card content goes here'}
                ]
              }
            }
          }
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
    });

    test('Transform with nested Positioned children', () {
      final json = {
        'type': 'Transform',
        'transform': {'angle': 0.1},
        'child': {
          'type': 'Stack',
          'children': [
            {
              'type': 'Positioned',
              'all': 0,
              'child': {'type': 'Container', 'color': '#FF0000'}
            },
            {
              'type': 'Positioned',
              'top': 20,
              'left': 20,
              'right': 20,
              'bottom': 20,
              'child': {'type': 'Container', 'color': '#00FF00'}
            },
            {
              'type': 'Positioned',
              'top': 40,
              'left': 40,
              'right': 40,
              'bottom': 40,
              'child': {'type': 'Container', 'color': '#0000FF'}
            }
          ]
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Transform>());
    });

    test('Wrap with varied child sizes creates complex layout', () {
      final json = {
        'type': 'Wrap',
        'spacing': 8,
        'runSpacing': 8,
        'children': [
          {'type': 'Chip', 'label': 'Small'},
          {'type': 'Chip', 'label': 'Medium Chip'},
          {'type': 'Chip', 'label': 'Very Long Chip Label'},
          {'type': 'Chip', 'label': 'Small'},
          {'type': 'Chip', 'label': 'Another'},
          {'type': 'Chip', 'label': 'Yet Another Long One'},
          {'type': 'Chip', 'label': 'End'}
        ]
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Wrap>());
    });

    test('CustomMultiChildLayout with complex positioning', () {
      final json = {
        'type': 'Column',
        'children': [
          {
            'type': 'Container',
            'height': 300,
            'child': {
              'type': 'Stack',
              'children': [
                {
                  'type': 'Positioned',
                  'top': 10,
                  'left': 10,
                  'child': {'type': 'Text', 'text': 'Top Left'}
                },
                {
                  'type': 'Positioned',
                  'top': 10,
                  'right': 10,
                  'child': {'type': 'Text', 'text': 'Top Right'}
                },
                {
                  'type': 'Positioned',
                  'bottom': 10,
                  'left': 10,
                  'child': {'type': 'Text', 'text': 'Bottom Left'}
                },
                {
                  'type': 'Positioned',
                  'bottom': 10,
                  'right': 10,
                  'child': {'type': 'Text', 'text': 'Bottom Right'}
                },
                {
                  'type': 'Center',
                  'child': {'type': 'Text', 'text': 'Center'}
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

    test('Deeply nested Container with multiple wrapper levels', () {
      final json = {
        'type': 'Padding',
        'padding': 16,
        'child': {
          'type': 'Card',
          'child': {
            'type': 'Padding',
            'padding': 12,
            'child': {
              'type': 'Column',
              'children': [
                {
                  'type': 'Container',
                  'padding': 8,
                  'child': {
                    'type': 'Row',
                    'children': [
                      {
                        'type': 'Expanded',
                        'child': {
                          'type': 'Container',
                          'padding': 4,
                          'child': {'type': 'Text', 'text': 'Left'}
                        }
                      },
                      {
                        'type': 'Expanded',
                        'child': {
                          'type': 'Container',
                          'padding': 4,
                          'child': {'type': 'Text', 'text': 'Right'}
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        }
      };

      final widget = UIRenderer.render(json);

      expect(widget, isNotNull);
      expect(widget, isA<Padding>());
    });
  });
}
