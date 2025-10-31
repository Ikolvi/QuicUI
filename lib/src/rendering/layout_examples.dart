/// Phase 1 Widget JSON Examples
/// 
/// Comprehensive JSON examples for all 12 Phase 1 widgets
/// These examples demonstrate proper usage and properties

// SliverAppBar Example
final sliverAppBarExample = {
  'type': 'SliverAppBar',
  'properties': {
    'title': 'Collapsible App Bar',
    'expandedHeight': 250.0,
    'floating': true,
    'pinned': true,
    'snap': true,
    'backgroundColor': '#2196F3',
    'foregroundColor': '#FFFFFF',
  },
  'children': [
    {
      'type': 'Container',
      'properties': {
        'color': '#1976D2',
        'padding': 16.0,
      },
      'children': [
        {
          'type': 'Text',
          'properties': {
            'text': 'Flexible Space Content',
            'color': '#FFFFFF',
            'fontSize': 18.0,
          },
        },
      ],
    },
  ],
};

// Avatar Example
final avatarExample = {
  'type': 'Avatar',
  'properties': {
    'imageUrl': 'https://example.com/avatar.jpg',
    'initials': 'JD',
    'size': 80.0,
    'backgroundColor': '#FF6B6B',
    'textColor': '#FFFFFF',
  },
};

// ProgressBar Example
final progressBarExample = {
  'type': 'ProgressBar',
  'properties': {
    'value': 0.75,
    'minValue': 0.0,
    'maxValue': 100.0,
    'showLabel': true,
    'height': 8.0,
    'backgroundColor': '#E0E0E0',
    'valueColor': '#4CAF50',
  },
};

// CircularProgress Example
final circularProgressExample = {
  'type': 'CircularProgress',
  'properties': {
    'value': 0.65,
    'size': 120.0,
    'showLabel': true,
    'strokeWidth': 6.0,
    'valueColor': '#2196F3',
    'backgroundColor': '#E3F2FD',
  },
};

// Tag Example
final tagExample = {
  'type': 'Tag',
  'properties': {
    'label': 'Flutter',
    'backgroundColor': '#9C27B0',
    'textColor': '#FFFFFF',
    'onDismissed': true,
  },
};

// FittedBox Example
final fittedBoxExample = {
  'type': 'FittedBox',
  'properties': {
    'fit': 'contain',
  },
  'children': [
    {
      'type': 'Text',
      'properties': {
        'text': 'Fitted Text Content',
        'fontSize': 48.0,
      },
    },
  ],
};

// ExpansionTile Example
final expansionTileExample = {
  'type': 'ExpansionTile',
  'properties': {
    'title': 'Settings',
    'subtitle': 'Tap to expand',
    'initiallyExpanded': false,
    'backgroundColor': '#F5F5F5',
  },
  'children': [
    {
      'type': 'ListTile',
      'properties': {
        'title': 'Dark Mode',
        'trailing': {'type': 'Switch'},
      },
    },
    {
      'type': 'ListTile',
      'properties': {
        'title': 'Notifications',
        'trailing': {'type': 'Switch'},
      },
    },
  ],
};

// Stepper Example
final stepperExample = {
  'type': 'Stepper',
  'properties': {
    'type': 'vertical',
    'currentStep': 1,
  },
  'children': [
    {
      'title': 'Personal Info',
      'subtitle': 'Enter your details',
      'content': {
        'type': 'Column',
        'children': [
          {
            'type': 'TextField',
            'properties': {
              'label': 'Name',
              'hintText': 'Enter your name',
            },
          },
          {
            'type': 'TextField',
            'properties': {
              'label': 'Email',
              'hintText': 'Enter your email',
            },
          },
        ],
      },
    },
    {
      'title': 'Address',
      'subtitle': 'Provide your address',
      'content': {
        'type': 'Column',
        'children': [
          {
            'type': 'TextField',
            'properties': {
              'label': 'Street',
              'hintText': 'Enter street address',
            },
          },
        ],
      },
    },
  ],
};

// DataTable Example
final dataTableExample = {
  'type': 'DataTable',
  'properties': {
    'columns': ['Name', 'Email', 'Status'],
  },
  'children': [
    {
      'cells': ['John Doe', 'john@example.com', 'Active'],
    },
    {
      'cells': ['Jane Smith', 'jane@example.com', 'Inactive'],
    },
    {
      'cells': ['Bob Johnson', 'bob@example.com', 'Active'],
    },
  ],
};

// PageView Example
final pageViewExample = {
  'type': 'PageView',
  'properties': {
    'scrollDirection': 'horizontal',
  },
  'children': [
    {
      'type': 'Container',
      'properties': {
        'color': '#FF6B6B',
      },
      'children': [
        {
          'type': 'Center',
          'children': [
            {
              'type': 'Text',
              'properties': {
                'text': 'Page 1',
                'color': '#FFFFFF',
                'fontSize': 24.0,
              },
            },
          ],
        },
      ],
    },
    {
      'type': 'Container',
      'properties': {
        'color': '#4ECDC4',
      },
      'children': [
        {
          'type': 'Center',
          'children': [
            {
              'type': 'Text',
              'properties': {
                'text': 'Page 2',
                'color': '#FFFFFF',
                'fontSize': 24.0,
              },
            },
          ],
        },
      ],
    },
  ],
};

// SnackBar Example (typically shown via ScaffoldMessenger)
final snackBarExample = {
  'type': 'SnackBar',
  'properties': {
    'message': 'This is a snackbar message',
    'duration': 3,
    'backgroundColor': '#323232',
    'textColor': '#FFFFFF',
  },
};

// BottomSheet Example
final bottomSheetExample = {
  'type': 'BottomSheet',
  'properties': {
    'title': 'Share Options',
    'height': 300.0,
    'backgroundColor': '#FFFFFF',
  },
  'children': [
    {
      'type': 'ListTile',
      'properties': {
        'title': 'Share via Email',
        'leading': {'type': 'Icon', 'properties': {'icon': 'mail'}},
      },
    },
    {
      'type': 'ListTile',
      'properties': {
        'title': 'Share via WhatsApp',
        'leading': {'type': 'Icon', 'properties': {'icon': 'chat'}},
      },
    },
    {
      'type': 'ListTile',
      'properties': {
        'title': 'Share via Facebook',
        'leading': {'type': 'Icon', 'properties': {'icon': 'share'}},
      },
    },
  ],
};

// Complex Example: Complete Profile Screen using Phase 1 Widgets
final complexProfileScreenExample = {
  'type': 'Scaffold',
  'properties': {
    'backgroundColor': '#F5F5F5',
  },
  'appBar': {
    'type': 'AppBar',
    'properties': {
      'title': 'User Profile',
      'backgroundColor': '#2196F3',
      'foregroundColor': '#FFFFFF',
    },
  },
  'children': [
    {
      'type': 'SingleChildScrollView',
      'children': [
        {
          'type': 'Column',
          'properties': {
            'mainAxisAlignment': 'start',
            'crossAxisAlignment': 'center',
            'spacing': 16.0,
          },
          'children': [
            // Avatar Section
            {
              'type': 'Padding',
              'properties': {'padding': 16.0},
              'children': [
                {
                  'type': 'Avatar',
                  'properties': {
                    'imageUrl': 'https://example.com/user.jpg',
                    'initials': 'JD',
                    'size': 100.0,
                    'backgroundColor': '#2196F3',
                  },
                },
              ],
            },
            // Stats Section
            {
              'type': 'Row',
              'properties': {
                'mainAxisAlignment': 'spaceEvenly',
              },
              'children': [
                {
                  'type': 'Column',
                  'children': [
                    {
                      'type': 'Text',
                      'properties': {
                        'text': '1.2K',
                        'fontSize': 20.0,
                        'fontWeight': 'bold',
                      },
                    },
                    {
                      'type': 'Text',
                      'properties': {
                        'text': 'Followers',
                        'fontSize': 12.0,
                      },
                    },
                  ],
                },
                {
                  'type': 'Column',
                  'children': [
                    {
                      'type': 'Text',
                      'properties': {
                        'text': '500',
                        'fontSize': 20.0,
                        'fontWeight': 'bold',
                      },
                    },
                    {
                      'type': 'Text',
                      'properties': {
                        'text': 'Following',
                        'fontSize': 12.0,
                      },
                    },
                  ],
                },
              ],
            },
            // Progress Section
            {
              'type': 'Card',
              'properties': {
                'margin': 16.0,
              },
              'children': [
                {
                  'type': 'Padding',
                  'properties': {'padding': 16.0},
                  'children': [
                    {
                      'type': 'Column',
                      'children': [
                        {
                          'type': 'Text',
                          'properties': {
                            'text': 'Profile Completion',
                            'fontSize': 16.0,
                            'fontWeight': 'bold',
                          },
                        },
                        {
                          'type': 'Padding',
                          'properties': {'padding': '8.0 0.0'},
                          'children': [
                            {
                              'type': 'ProgressBar',
                              'properties': {
                                'value': 0.85,
                                'showLabel': true,
                                'valueColor': '#4CAF50',
                              },
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
              ],
            },
            // Settings Expansion Tile
            {
              'type': 'ExpansionTile',
              'properties': {
                'title': 'Account Settings',
                'subtitle': 'Manage your account',
              },
              'children': [
                {
                  'type': 'ListTile',
                  'properties': {
                    'title': 'Privacy',
                  },
                },
                {
                  'type': 'ListTile',
                  'properties': {
                    'title': 'Security',
                  },
                },
              ],
            },
          ],
        },
      ],
    },
  ],
};
