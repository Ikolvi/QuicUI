/// Phase 3 Widget Examples
/// 
/// Comprehensive JSON examples for all Phase 3 layout and advanced widgets

class Phase3Examples {
  /// CustomScrollView Example - Basic mixed scrolling
  static const Map<String, dynamic> customScrollViewExample = {
    'type': 'CustomScrollView',
    'properties': {},
    'children': [
      {
        'type': 'SliverAppBar',
        'properties': {
          'title': 'Custom Scroll View',
        }
      },
      {
        'type': 'SliverList',
        'properties': {
          'itemCount': 10,
        }
      }
    ]
  };

  /// SliverList Example - Efficient list rendering
  static const Map<String, dynamic> sliverListExample = {
    'type': 'SliverList',
    'properties': {
      'itemCount': 100,
      'itemExtent': null,
    }
  };

  /// SliverList with fixed height example
  static const Map<String, dynamic> sliverListFixedExample = {
    'type': 'SliverList',
    'properties': {
      'itemCount': 50,
      'itemExtent': 60.0,
    }
  };

  /// SliverGrid Example - Grid in CustomScrollView
  static const Map<String, dynamic> sliverGridExample = {
    'type': 'SliverGrid',
    'properties': {
      'crossAxisCount': 3,
      'childAspectRatio': 1.0,
      'crossAxisSpacing': 8.0,
      'mainAxisSpacing': 8.0,
    }
  };

  /// SliverGrid with different aspect ratio
  static const Map<String, dynamic> sliverGridAspectExample = {
    'type': 'SliverGrid',
    'properties': {
      'crossAxisCount': 2,
      'childAspectRatio': 0.75,
      'crossAxisSpacing': 12.0,
      'mainAxisSpacing': 12.0,
    }
  };

  /// Flow Example - Custom widget positioning
  static const Map<String, dynamic> flowExample = {
    'type': 'Flow',
    'properties': {
      'offsetX': 10.0,
      'offsetY': 10.0,
      'spacing': 15.0,
    }
  };

  /// Flow with different offsets
  static const Map<String, dynamic> flowOffsetExample = {
    'type': 'Flow',
    'properties': {
      'offsetX': 20.0,
      'offsetY': 20.0,
      'spacing': 20.0,
    }
  };

  /// LayoutBuilder Example - Responsive layout
  static const Map<String, dynamic> layoutBuilderExample = {
    'type': 'LayoutBuilder',
    'properties': {
      'backgroundColor': '#F5F5F5',
      'padding': 16.0,
      'gapWidth': 16.0,
    }
  };

  /// LayoutBuilder with custom styling
  static const Map<String, dynamic> layoutBuilderStyleExample = {
    'type': 'LayoutBuilder',
    'properties': {
      'backgroundColor': '#E3F2FD',
      'padding': 24.0,
      'gapWidth': 20.0,
    }
  };

  /// ResponsiveWidget Example - Screen size detection
  static const Map<String, dynamic> responsiveWidgetExample = {
    'type': 'ResponsiveWidget',
    'properties': {
      'backgroundColor': '#FFFFFF',
      'padding': 16.0,
      'fontSize': 16.0,
    }
  };

  /// ResponsiveWidget with large text
  static const Map<String, dynamic> responsiveWidgetLargeExample = {
    'type': 'ResponsiveWidget',
    'properties': {
      'backgroundColor': '#F0F0F0',
      'padding': 20.0,
      'fontSize': 20.0,
    }
  };

  /// Advanced SliverAppBar Example - Collapsible header
  static const Map<String, dynamic> advancedSliverAppBarExample = {
    'type': 'AdvancedSliverAppBar',
    'properties': {
      'title': 'Collapsible Header',
      'expandedHeight': 250.0,
      'floating': false,
      'pinned': true,
      'snap': false,
      'backgroundColor': '#2196F3',
      'description': 'Scroll to see the effect',
    }
  };

  /// Advanced SliverAppBar with floating effect
  static const Map<String, dynamic> advancedSliverAppBarFloatingExample = {
    'type': 'AdvancedSliverAppBar',
    'properties': {
      'title': 'Floating Header',
      'expandedHeight': 200.0,
      'floating': true,
      'pinned': false,
      'snap': true,
      'backgroundColor': '#FF5722',
      'description': 'Header floats on scroll up',
    }
  };

  /// NestedScrollView Example - Multiple scrollers
  static const Map<String, dynamic> nestedScrollViewExample = {
    'type': 'NestedScrollView',
    'properties': {
      'title': 'Nested Scrolling',
      'bodyText': 'This is a nested scroll view with header and body scrolling separately',
    }
  };

  /// NestedScrollView with custom content
  static const Map<String, dynamic> nestedScrollViewCustomExample = {
    'type': 'NestedScrollView',
    'properties': {
      'title': 'Custom Content',
      'bodyText': 'You can scroll the header and body independently in this layout',
    }
  };

  /// AnimatedBuilder Example - Rotating animation
  static const Map<String, dynamic> animatedBuilderExample = {
    'type': 'AnimatedBuilder',
    'properties': {
      'duration': 500,
      'animationType': 'rotate',
    }
  };

  /// AnimatedBuilder with longer duration
  static const Map<String, dynamic> animatedBuilderSlowExample = {
    'type': 'AnimatedBuilder',
    'properties': {
      'duration': 2000,
      'animationType': 'rotate',
    }
  };

  /// TabBarViewAdvanced Example - Three tabs
  static const Map<String, dynamic> tabBarViewAdvancedExample = {
    'type': 'TabBarViewAdvanced',
    'properties': {
      'title': 'Tab Navigation',
      'tabCount': 3,
    }
  };

  /// TabBarViewAdvanced with more tabs
  static const Map<String, dynamic> tabBarViewAdvancedManyExample = {
    'type': 'TabBarViewAdvanced',
    'properties': {
      'title': 'Multiple Tabs',
      'tabCount': 5,
    }
  };

  /// PinchZoom Example - Image zoom
  static const Map<String, dynamic> pinchZoomExample = {
    'type': 'PinchZoom',
    'properties': {
      'minScale': 0.5,
      'maxScale': 4.0,
      'backgroundColor': '#FAFAFA',
      'text': 'Pinch to zoom',
      'fontSize': 18.0,
    }
  };

  /// PinchZoom with different scale range
  static const Map<String, dynamic> pinchZoomWideExample = {
    'type': 'PinchZoom',
    'properties': {
      'minScale': 1.0,
      'maxScale': 5.0,
      'backgroundColor': '#E8F5E9',
      'text': 'Use pinch gesture to zoom',
      'fontSize': 16.0,
    }
  };

  /// VirtualizedList Example - Large list
  static const Map<String, dynamic> virtualizedListExample = {
    'type': 'VirtualizedList',
    'properties': {
      'itemCount': 1000,
    }
  };

  /// VirtualizedList with smaller count
  static const Map<String, dynamic> virtualizedListSmallExample = {
    'type': 'VirtualizedList',
    'properties': {
      'itemCount': 50,
    }
  };

  /// StickyHeaders Example - Sections with headers
  static const Map<String, dynamic> stickyHeadersExample = {
    'type': 'StickyHeaders',
    'properties': {
      'sections': [
        {'title': 'Section 1'},
        {'title': 'Section 2'},
        {'title': 'Section 3'},
      ],
    }
  };

  /// StickyHeaders with more sections
  static const Map<String, dynamic> stickyHeadersManyExample = {
    'type': 'StickyHeaders',
    'properties': {
      'sections': [
        {'title': 'A-C'},
        {'title': 'D-F'},
        {'title': 'G-I'},
        {'title': 'J-L'},
        {'title': 'M-O'},
      ],
    }
  };

  // ============ COMPLEX LAYOUT EXAMPLES ============

  /// Dashboard Layout Example - Responsive grid
  static const Map<String, dynamic> dashboardLayoutExample = {
    'type': 'LayoutBuilder',
    'properties': {
      'backgroundColor': '#F5F5F5',
      'padding': 16.0,
      'gapWidth': 16.0,
    },
    'children': [
      {
        'type': 'Column',
        'properties': {'spacing': 16},
        'children': [
          {
            'type': 'Card',
            'properties': {
              'backgroundColor': '#FFFFFF',
              'elevation': 2,
            }
          },
          {
            'type': 'Card',
            'properties': {
              'backgroundColor': '#FFFFFF',
              'elevation': 2,
            }
          }
        ]
      }
    ]
  };

  /// News Feed Example - Custom scroll with slivers
  static const Map<String, dynamic> newsFeedExample = {
    'type': 'CustomScrollView',
    'properties': {},
    'children': [
      {
        'type': 'SliverAppBar',
        'properties': {
          'title': 'News Feed',
          'floating': true,
        }
      },
      {
        'type': 'SliverList',
        'properties': {
          'itemCount': 20,
        }
      }
    ]
  };

  /// Product Gallery Example - Grid with pinch zoom
  static const Map<String, dynamic> productGalleryExample = {
    'type': 'Column',
    'properties': {'spacing': 0},
    'children': [
      {
        'type': 'PinchZoom',
        'properties': {
          'minScale': 1.0,
          'maxScale': 3.0,
          'backgroundColor': '#FFFFFF',
          'text': 'Gallery - Pinch to zoom',
          'fontSize': 16.0,
        }
      }
    ]
  };

  /// Collapsible Menu Example - SliverAppBar with flexible space
  static const Map<String, dynamic> collapsibleMenuExample = {
    'type': 'AdvancedSliverAppBar',
    'properties': {
      'title': 'Collapsible Menu',
      'expandedHeight': 300.0,
      'floating': false,
      'pinned': true,
      'snap': false,
      'backgroundColor': '#1976D2',
      'description': 'Menu items shown when expanded',
    }
  };

  /// Photo Album Example - SliverGrid
  static const Map<String, dynamic> photoAlbumExample = {
    'type': 'CustomScrollView',
    'properties': {},
    'children': [
      {
        'type': 'SliverAppBar',
        'properties': {
          'title': 'Photo Album',
          'pinned': true,
        }
      },
      {
        'type': 'SliverGrid',
        'properties': {
          'crossAxisCount': 3,
          'childAspectRatio': 1.0,
          'crossAxisSpacing': 4.0,
          'mainAxisSpacing': 4.0,
        }
      }
    ]
  };

  /// Master-Detail Layout Example - LayoutBuilder
  static const Map<String, dynamic> masterDetailExample = {
    'type': 'LayoutBuilder',
    'properties': {
      'backgroundColor': '#FFFFFF',
      'padding': 0,
      'gapWidth': 16.0,
    }
  };

  /// Chat Interface Example - Virtual list
  static const Map<String, dynamic> chatInterfaceExample = {
    'type': 'Column',
    'properties': {
      'spacing': 0,
      'crossAxisAlignment': 'stretch',
    },
    'children': [
      {
        'type': 'Expanded',
        'properties': {'flex': 1},
        'children': [
          {
            'type': 'VirtualizedList',
            'properties': {
              'itemCount': 100,
            }
          }
        ]
      },
      {
        'type': 'Container',
        'properties': {
          'height': 60,
          'backgroundColor': '#F5F5F5',
        }
      }
    ]
  };

  /// Settings Panel Example - Sticky headers
  static const Map<String, dynamic> settingsPanelExample = {
    'type': 'StickyHeaders',
    'properties': {
      'sections': [
        {'title': 'Display'},
        {'title': 'Notifications'},
        {'title': 'Privacy'},
        {'title': 'About'},
      ],
    }
  };

  /// Animated Loading Example - AnimatedBuilder
  static const Map<String, dynamic> animatedLoadingExample = {
    'type': 'Column',
    'properties': {
      'spacing': 16,
      'mainAxisAlignment': 'center',
      'crossAxisAlignment': 'center',
    },
    'children': [
      {
        'type': 'AnimatedBuilder',
        'properties': {
          'duration': 1000,
          'animationType': 'rotate',
        }
      },
      {
        'type': 'Text',
        'properties': {
          'text': 'Loading...',
          'fontSize': 16,
        }
      }
    ]
  };

  /// Tab Navigation Example - TabBarViewAdvanced
  static const Map<String, dynamic> tabNavigationExample = {
    'type': 'TabBarViewAdvanced',
    'properties': {
      'title': 'App Navigation',
      'tabCount': 4,
    }
  };

  /// Responsive Design Example
  static const Map<String, dynamic> responsiveDesignExample = {
    'type': 'ResponsiveWidget',
    'properties': {
      'backgroundColor': '#ECEFF1',
      'padding': 24.0,
      'fontSize': 18.0,
    }
  };

  /// Get all examples as a map
  static Map<String, Map<String, dynamic>> getAllExamples() => {
    'customScrollView': customScrollViewExample,
    'sliverList': sliverListExample,
    'sliverListFixed': sliverListFixedExample,
    'sliverGrid': sliverGridExample,
    'sliverGridAspect': sliverGridAspectExample,
    'flow': flowExample,
    'flowOffset': flowOffsetExample,
    'layoutBuilder': layoutBuilderExample,
    'layoutBuilderStyle': layoutBuilderStyleExample,
    'responsiveWidget': responsiveWidgetExample,
    'responsiveWidgetLarge': responsiveWidgetLargeExample,
    'advancedSliverAppBar': advancedSliverAppBarExample,
    'advancedSliverAppBarFloating': advancedSliverAppBarFloatingExample,
    'nestedScrollView': nestedScrollViewExample,
    'nestedScrollViewCustom': nestedScrollViewCustomExample,
    'animatedBuilder': animatedBuilderExample,
    'animatedBuilderSlow': animatedBuilderSlowExample,
    'tabBarViewAdvanced': tabBarViewAdvancedExample,
    'tabBarViewAdvancedMany': tabBarViewAdvancedManyExample,
    'pinchZoom': pinchZoomExample,
    'pinchZoomWide': pinchZoomWideExample,
    'virtualizedList': virtualizedListExample,
    'virtualizedListSmall': virtualizedListSmallExample,
    'stickyHeaders': stickyHeadersExample,
    'stickyHeadersMany': stickyHeadersManyExample,
    'dashboardLayout': dashboardLayoutExample,
    'newsFeed': newsFeedExample,
    'productGallery': productGalleryExample,
    'collapsibleMenu': collapsibleMenuExample,
    'photoAlbum': photoAlbumExample,
    'masterDetail': masterDetailExample,
    'chatInterface': chatInterfaceExample,
    'settingsPanel': settingsPanelExample,
    'animatedLoading': animatedLoadingExample,
    'tabNavigation': tabNavigationExample,
    'responsiveDesign': responsiveDesignExample,
  };
}
