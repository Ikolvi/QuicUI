/// Phase 4 Examples: Navigation Widget Usage Examples
/// Demonstrates practical implementations of all 13 navigation widgets

class Phase4Examples {
  /// Navigation Rail examples
  static List<Map<String, dynamic>> navigationRailExamples = [
    {
      'name': 'Basic Navigation Rail',
      'description': 'Simple rail with 4 destinations',
      'properties': {
        'destinations': [
          {'label': 'Home', 'icon': 'home'},
          {'label': 'Search', 'icon': 'search'},
          {'label': 'Account', 'icon': 'person'},
          {'label': 'Settings', 'icon': 'settings'},
        ],
        'selectedIndex': 0,
      },
    },
    {
      'name': 'Extended Navigation Rail',
      'description': 'Rail with extended mode showing labels',
      'properties': {
        'destinations': [
          {'label': 'Dashboard', 'icon': 'home'},
          {'label': 'Analytics', 'icon': 'search'},
          {'label': 'Profile', 'icon': 'person'},
        ],
        'selectedIndex': 0,
        'extended': true,
        'minExtendedWidth': 256,
      },
    },
    {
      'name': 'Styled Navigation Rail',
      'description': 'Rail with custom colors',
      'properties': {
        'destinations': [
          {'label': 'Home', 'icon': 'home'},
          {'label': 'Favorites', 'icon': 'favorite'},
          {'label': 'Cart', 'icon': 'shopping_cart'},
        ],
        'backgroundColor': '#F5F5F5',
        'selectedIndex': 1,
      },
    },
  ];

  /// Breadcrumb examples
  static List<Map<String, dynamic>> breadcrumbExamples = [
    {
      'name': 'Simple Breadcrumb',
      'description': 'Basic navigation breadcrumb trail',
      'properties': {
        'items': [
          {'label': 'Home', 'onTap': true},
          {'label': 'Products', 'onTap': true},
          {'label': 'Electronics', 'onTap': true},
          {'label': 'Smartphones', 'onTap': false},
        ],
      },
    },
    {
      'name': 'Custom Separator',
      'description': 'Breadcrumb with arrow separator',
      'properties': {
        'items': [
          {'label': 'Dashboard', 'onTap': true},
          {'label': 'Settings', 'onTap': true},
          {'label': 'Privacy', 'onTap': false},
        ],
        'separator': '>',
      },
    },
    {
      'name': 'Large Font Breadcrumb',
      'description': 'Breadcrumb with bigger text',
      'properties': {
        'items': [
          {'label': 'Blog', 'onTap': true},
          {'label': 'Category', 'onTap': true},
          {'label': 'Article', 'onTap': false},
        ],
        'fontSize': 18,
        'spacing': 12,
      },
    },
  ];

  /// Stacked Navigation examples
  static List<Map<String, dynamic>> stackedNavigationExamples = [
    {
      'name': 'Basic Stack',
      'description': 'Simple screen stack navigation',
      'properties': {
        'screens': [
          {'title': 'Home Screen', 'content': 'Welcome'},
          {'title': 'Details Screen', 'content': 'Details'},
          {'title': 'Settings Screen', 'content': 'Settings'},
        ],
        'currentIndex': 0,
      },
    },
    {
      'name': 'Fast Animation Stack',
      'description': 'Stack with quick animations',
      'properties': {
        'screens': [
          {'title': 'Screen 1'},
          {'title': 'Screen 2'},
          {'title': 'Screen 3'},
        ],
        'currentIndex': 1,
        'animationDuration': 150,
      },
    },
  ];

  /// Navigation Stack examples
  static List<Map<String, dynamic>> navigationStackExamples = [
    {
      'name': 'Simple Back Stack',
      'description': 'Basic back navigation stack',
      'properties': {
        'stack': ['Home', 'Products', 'Details'],
      },
    },
    {
      'name': 'Deep Navigation Stack',
      'description': 'Deep nested navigation',
      'properties': {
        'stack': [
          'Home',
          'Category',
          'Subcategory',
          'Product',
          'Review',
        ],
      },
    },
  ];

  /// Drawer Navigation examples
  static List<Map<String, dynamic>> drawerNavigationExamples = [
    {
      'name': 'Basic Drawer Menu',
      'description': 'Simple navigation drawer',
      'properties': {
        'headerTitle': 'Menu',
        'items': [
          {'label': 'Home', 'icon': 'home'},
          {'label': 'Profile', 'icon': 'person'},
          {'label': 'Settings', 'icon': 'settings'},
          {'label': 'About', 'icon': 'info'},
        ],
      },
    },
    {
      'name': 'App Drawer',
      'description': 'Drawer with app-specific menu',
      'properties': {
        'headerTitle': 'MyApp',
        'items': [
          {'label': 'Dashboard'},
          {'label': 'Analytics'},
          {'label': 'Reports'},
          {'label': 'Logout'},
        ],
        'backgroundColor': '#FAFAFA',
      },
    },
  ];

  /// Menu Bar examples
  static List<Map<String, dynamic>> menuBarExamples = [
    {
      'name': 'Simple Menu Bar',
      'description': 'Desktop-style menu bar',
      'properties': {
        'items': [
          {
            'label': 'File',
            'subItems': [
              {'label': 'New'},
              {'label': 'Open'},
              {'label': 'Save'},
            ],
          },
          {
            'label': 'Edit',
            'subItems': [
              {'label': 'Cut'},
              {'label': 'Copy'},
              {'label': 'Paste'},
            ],
          },
        ],
      },
    },
    {
      'name': 'Complete Menu Bar',
      'description': 'Full application menu',
      'properties': {
        'items': [
          {
            'label': 'File',
            'subItems': [
              {'label': 'New Project'},
              {'label': 'Open'},
              {'label': 'Save'},
              {'label': 'Exit'},
            ],
          },
          {
            'label': 'Edit',
            'subItems': [
              {'label': 'Undo'},
              {'label': 'Redo'},
              {'label': 'Find'},
            ],
          },
          {
            'label': 'Help',
            'subItems': [
              {'label': 'Documentation'},
              {'label': 'About'},
            ],
          },
        ],
        'height': 56,
      },
    },
  ];

  /// Side Bar examples
  static List<Map<String, dynamic>> sideBarExamples = [
    {
      'name': 'Collapsible Sidebar',
      'description': 'Sidebar with expandable items',
      'properties': {
        'items': [
          {
            'label': 'Dashboard',
            'expanded': false,
            'subItems': [],
          },
          {
            'label': 'Products',
            'expanded': true,
            'subItems': [
              {'label': 'Electronics'},
              {'label': 'Clothing'},
              {'label': 'Books'},
            ],
          },
          {
            'label': 'Orders',
            'expanded': false,
            'subItems': [],
          },
        ],
      },
    },
    {
      'name': 'Admin Sidebar',
      'description': 'Admin panel sidebar',
      'properties': {
        'items': [
          {'label': 'Users', 'expanded': false, 'subItems': []},
          {'label': 'Content', 'expanded': true, 'subItems': [
            {'label': 'Pages'},
            {'label': 'Posts'},
            {'label': 'Media'},
          ]},
          {'label': 'Settings', 'expanded': false, 'subItems': []},
        ],
        'width': 280,
        'backgroundColor': '#F0F0F0',
      },
    },
  ];

  /// Context Menu examples
  static List<Map<String, dynamic>> contextMenuExamples = [
    {
      'name': 'Basic Context Menu',
      'description': 'Right-click menu for actions',
      'properties': {
        'items': [
          {'label': 'Cut', 'icon': 'cut'},
          {'label': 'Copy', 'icon': 'copy'},
          {'label': 'Paste', 'icon': 'paste'},
        ],
        'triggerText': 'Right-click for options',
      },
    },
    {
      'name': 'Item Context Menu',
      'description': 'Context menu on list item',
      'properties': {
        'items': [
          {'label': 'Edit'},
          {'label': 'Delete'},
          {'label': 'Share'},
          {'label': 'Details'},
        ],
        'triggerText': 'Right-click item',
      },
    },
  ];

  /// Advanced Bottom Navigation examples
  static List<Map<String, dynamic>> advancedBottomNavExamples = [
    {
      'name': 'Bottom Nav with Badges',
      'description': 'Bottom navigation with notification badges',
      'properties': {
        'items': [
          {'label': 'Home', 'icon': 'home'},
          {'label': 'Messages', 'icon': 'mail', 'badge': '3'},
          {'label': 'Notifications', 'icon': 'notifications', 'badge': '12'},
          {'label': 'Profile', 'icon': 'person'},
        ],
        'selectedIndex': 0,
      },
    },
    {
      'name': 'E-commerce Bottom Nav',
      'description': 'E-commerce app bottom navigation',
      'properties': {
        'items': [
          {'label': 'Home', 'icon': 'home'},
          {'label': 'Search', 'icon': 'search'},
          {'label': 'Cart', 'icon': 'shopping_cart', 'badge': '2'},
          {'label': 'Account', 'icon': 'account'},
        ],
        'selectedIndex': 2,
        'backgroundColor': '#FFFFFF',
      },
    },
  ];

  /// Enhanced TabBar examples
  static List<Map<String, dynamic>> tabBarEnhancedExamples = [
    {
      'name': 'Basic Animated Tabs',
      'description': 'Tabs with animated indicator',
      'properties': {
        'tabs': [
          {'label': 'Tab 1'},
          {'label': 'Tab 2'},
          {'label': 'Tab 3'},
        ],
        'selectedIndex': 0,
      },
    },
    {
      'name': 'Colored Tab Bar',
      'description': 'Tabs with custom colors',
      'properties': {
        'tabs': [
          {'label': 'Overview'},
          {'label': 'Details'},
          {'label': 'Reviews'},
          {'label': 'Specs'},
        ],
        'selectedIndex': 1,
        'indicatorColor': '#2196F3',
        'backgroundColor': '#FFFFFF',
      },
    },
  ];

  /// Animated Drawer examples
  static List<Map<String, dynamic>> animatedDrawerExamples = [
    {
      'name': 'Smooth Drawer',
      'description': 'Drawer with smooth animation',
      'properties': {
        'items': [
          'Dashboard',
          'Profile',
          'Settings',
          'Logout',
        ],
        'isOpen': false,
        'animationDuration': 300,
      },
    },
    {
      'name': 'Quick Drawer',
      'description': 'Fast animated drawer',
      'properties': {
        'items': [
          'Home',
          'Explore',
          'Saved',
          'Settings',
        ],
        'isOpen': false,
        'animationDuration': 150,
      },
    },
  ];

  /// Pagination Navigation examples
  static List<Map<String, dynamic>> paginationNavExamples = [
    {
      'name': 'Simple Pagination',
      'description': 'Basic pagination controls',
      'properties': {
        'currentPage': 1,
        'totalPages': 10,
        'maxButtons': 5,
      },
    },
    {
      'name': 'Multi-page Pagination',
      'description': 'Pagination for large dataset',
      'properties': {
        'currentPage': 5,
        'totalPages': 100,
        'maxButtons': 7,
        'backgroundColor': '#FAFAFA',
      },
    },
  ];

  /// Complex Navigation Examples
  static List<Map<String, dynamic>> complexExamples = [
    {
      'name': 'Dashboard Layout',
      'description': 'Complete dashboard with rail + drawer navigation',
      'components': [
        'NavigationRail',
        'DrawerNavigation',
        'TabBarEnhanced',
      ],
    },
    {
      'name': 'E-commerce App',
      'description': 'Full e-commerce with bottom nav + search',
      'components': [
        'AdvancedBottomNav',
        'TabBarEnhanced',
        'Breadcrumb',
      ],
    },
    {
      'name': 'Admin Panel',
      'description': 'Admin interface with menu bar + sidebar',
      'components': [
        'MenuBar',
        'SideBar',
        'Breadcrumb',
        'PaginationNav',
      ],
    },
    {
      'name': 'Social App',
      'description': 'Social media with rail + context menus',
      'components': [
        'NavigationRail',
        'ContextMenu',
        'Breadcrumb',
      ],
    },
    {
      'name': 'Modal Navigation',
      'description': 'Navigation using stacked modals',
      'components': [
        'StackedNavigation',
        'NavigationStack',
        'AnimatedDrawer',
      ],
    },
  ];

  /// Get all examples
  static Map<String, List<Map<String, dynamic>>> getAllExamples() => {
    'NavigationRail': navigationRailExamples,
    'Breadcrumb': breadcrumbExamples,
    'StackedNavigation': stackedNavigationExamples,
    'NavigationStack': navigationStackExamples,
    'DrawerNavigation': drawerNavigationExamples,
    'MenuBar': menuBarExamples,
    'SideBar': sideBarExamples,
    'ContextMenu': contextMenuExamples,
    'AdvancedBottomNav': advancedBottomNavExamples,
    'TabBarEnhanced': tabBarEnhancedExamples,
    'AnimatedDrawer': animatedDrawerExamples,
    'PaginationNav': paginationNavExamples,
    'Complex': complexExamples,
  };

  /// Get example count
  static int getTotalExampleCount() {
    int total = 0;
    getAllExamples().forEach((key, value) {
      total += value.length;
    });
    return total;
  }
}
