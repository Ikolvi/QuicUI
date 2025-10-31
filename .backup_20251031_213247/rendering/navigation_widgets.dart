import 'package:flutter/material.dart';

/// Phase 4: Navigation Widgets - Advanced navigation patterns and routing helpers
/// Includes: NavigationRail, Breadcrumb, StackedNavigation, MenuBar, SideBar, ContextMenu, etc.
/// Note: Does NOT duplicate existing NavigationBar, TabBar, Drawer - creates advanced variants instead

class NavigationWidgets {
  /// NavigationRail with enhanced features, icons, and multiple destinations
  static Widget buildNavigationRail(Map<String, dynamic> properties, List<dynamic>? children) {
    final destinations = (properties['destinations'] as List?)?.map((e) {
      final label = e['label'] as String? ?? 'Item';
      final icon = _parseIcon(e['icon'] as String?);
      return NavigationRailDestination(
        icon: Icon(icon),
        label: Text(label),
        selectedIcon: Icon(Icons.check_circle),
      );
    }).toList() ?? [];

    final selectedIndex = (properties['selectedIndex'] as num?)?.toInt() ?? 0;
    final extended = properties['extended'] as bool? ?? false;
    final groupAlignment = (properties['groupAlignment'] as num?)?.toDouble() ?? -1.0;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;
    final minWidth = (properties['minWidth'] as num?)?.toDouble() ?? 80;
    final minExtendedWidth = (properties['minExtendedWidth'] as num?)?.toDouble() ?? 256;

    return Container(
      color: backgroundColor,
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {},
        extended: extended,
        groupAlignment: groupAlignment,
        destinations: destinations,
        minWidth: minWidth,
        minExtendedWidth: minExtendedWidth,
        leading: properties['leading'] != null ? Icon(Icons.home) : null,
        trailing: properties['trailing'] != null ? Icon(Icons.settings) : null,
      ),
    );
  }

  /// Breadcrumb navigation showing page hierarchy
  static Widget buildBreadcrumb(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) {
      final label = e['label'] as String? ?? 'Item';
      final onTap = e['onTap'] as bool? ?? false;
      return BreadcrumbItem(label: label, isClickable: onTap);
    }).toList() ?? [];

    final separator = properties['separator'] as String? ?? '/';
    final fontSize = (properties['fontSize'] as num?)?.toDouble() ?? 14;
    final spacing = (properties['spacing'] as num?)?.toDouble() ?? 8;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          items.length,
          (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return Row(
              children: [
                GestureDetector(
                  onTap: item.isClickable ? () {} : null,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: item.isClickable ? Colors.blue : Colors.black87,
                      decoration: item.isClickable ? TextDecoration.underline : null,
                    ),
                  ),
                ),
                if (!isLast) ...[
                  SizedBox(width: spacing),
                  Text(separator, style: TextStyle(fontSize: fontSize)),
                  SizedBox(width: spacing),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Advanced breadcrumb item data class
  static Widget buildBreadcrumbItem(Map<String, dynamic> properties, List<dynamic>? children) {
    final label = properties['label'] as String? ?? 'Item';
    final isClickable = properties['isClickable'] as bool? ?? false;
    
    return Text(
      label,
      style: TextStyle(
        color: isClickable ? Colors.blue : Colors.black87,
        decoration: isClickable ? TextDecoration.underline : null,
      ),
    );
  }

  /// Stacked navigation showing hierarchical view transitions
  static Widget buildStackedNavigation(Map<String, dynamic> properties, List<dynamic>? children) {
    final screens = (properties['screens'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final currentIndex = (properties['currentIndex'] as num?)?.toInt() ?? 0;
    final animationDuration = Duration(milliseconds: (properties['animationDuration'] as num?)?.toInt() ?? 300);

    return Stack(
      children: List.generate(
        screens.length,
        (index) {
          final screen = screens[index];
          final title = screen['title'] as String? ?? 'Screen $index';
          final isVisible = index == currentIndex;

          return AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: animationDuration,
            child: IgnorePointer(
              ignoring: !isVisible,
              child: Container(
                color: Colors.white,
                child: Scaffold(
                  appBar: AppBar(title: Text(title)),
                  body: Center(
                    child: Text('Screen: $title'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Navigation stack manager handling back navigation
  static Widget buildNavigationStack(Map<String, dynamic> properties, List<dynamic>? children) {
    final stack = (properties['stack'] as List?)?.cast<String>() ?? ['Home'];
    final canGoBack = stack.length > 1;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[200],
          child: Text('Stack: ${stack.join(" > ")}'),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Current: ${stack.last}'),
                SizedBox(height: 16),
                if (canGoBack)
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Go Back'),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Drawer-based navigation with menu items
  static Widget buildDrawerNavigation(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) => e['label'] as String? ?? 'Item').toList() ?? [];
    final headerTitle = properties['headerTitle'] as String? ?? 'Menu';
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;

    return Drawer(
      backgroundColor: backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(headerTitle, style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ...items.map((item) => ListTile(
            title: Text(item),
            onTap: () {},
            leading: Icon(Icons.navigate_next),
          )),
        ],
      ),
    );
  }

  /// Menu bar for desktop applications
  static Widget buildMenuBar(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) {
      final label = e['label'] as String? ?? 'Menu';
      final subItems = (e['subItems'] as List?)?.map((s) => s['label'] as String? ?? 'Item').toList() ?? [];
      return MenuBarItem(label: label, subItems: subItems);
    }).toList() ?? [];

    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.grey[200];
    final height = (properties['height'] as num?)?.toDouble() ?? 56;

    return Container(
      color: backgroundColor,
      height: height,
      child: Row(
        children: items.map((item) => _buildMenuBarButton(item)).toList(),
      ),
    );
  }

  static Widget _buildMenuBarButton(MenuBarItem item) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => item.subItems.map((subItem) {
        return PopupMenuItem(value: subItem, child: Text(subItem));
      }).toList(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(item.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      onSelected: (value) {},
    );
  }

  /// Side bar navigation with collapsible menu
  static Widget buildSideBar(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) {
      final label = e['label'] as String? ?? 'Item';
      final expanded = e['expanded'] as bool? ?? false;
      final subItems = (e['subItems'] as List?)?.map((s) => s['label'] as String? ?? 'Sub').toList() ?? [];
      return SideBarItem(label: label, expanded: expanded, subItems: subItems);
    }).toList() ?? [];

    final width = (properties['width'] as num?)?.toDouble() ?? 250;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.grey[100];

    return Container(
      width: width,
      color: backgroundColor,
      child: ListView(
        children: items.map((item) => _buildSideBarItem(item)).toList(),
      ),
    );
  }

  static Widget _buildSideBarItem(SideBarItem item, {int level = 0}) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: level * 16.0 + 8),
          child: ListTile(
            title: Text(item.label),
            trailing: item.subItems.isNotEmpty
                ? Icon(item.expanded ? Icons.expand_less : Icons.expand_more)
                : null,
            onTap: () {},
          ),
        ),
        if (item.expanded)
          ...item.subItems.map((subItem) => Padding(
            padding: EdgeInsets.only(left: (level + 1) * 16.0 + 8),
            child: ListTile(
              title: Text(subItem, style: TextStyle(fontSize: 13)),
              onTap: () {},
            ),
          )),
      ],
    );
  }

  /// Context menu for right-click actions
  static Widget buildContextMenu(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) => e['label'] as String? ?? 'Action').toList() ?? [];
    final triggerText = properties['triggerText'] as String? ?? 'Right-click me';

    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(details.globalPosition, items);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(triggerText),
      ),
    );
  }

  static void _showContextMenu(Offset position, List<String> items) {
    // Context menu would be shown via ShowMenu or custom implementation
  }

  /// Advanced bottom navigation with labels and badges
  static Widget buildAdvancedBottomNav(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) {
      final label = e['label'] as String? ?? 'Tab';
      final badge = e['badge'] as String?;
      final icon = _parseIcon(e['icon'] as String?);
      return BottomNavItem(label: label, icon: icon, badge: badge);
    }).toList() ?? [];

    final selectedIndex = (properties['selectedIndex'] as num?)?.toInt() ?? 0;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;
          return Expanded(
            child: Stack(
              children: [
                InkWell(
                  onTap: () {},
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon,
                            color: isSelected ? Colors.blue : Colors.grey,
                            size: 24),
                        SizedBox(height: 4),
                        Text(item.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.blue : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                ),
                if (item.badge != null)
                  Positioned(
                    right: 12,
                    top: 4,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(item.badge!,
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Enhanced TabBar with animated indicators
  static Widget buildTabBarEnhanced(Map<String, dynamic> properties, List<dynamic>? children) {
    final tabs = (properties['tabs'] as List?)?.map((e) => e['label'] as String? ?? 'Tab').toList() ?? [];
    final selectedIndex = (properties['selectedIndex'] as num?)?.toInt() ?? 0;
    final indicatorColor = _parseColor(properties['indicatorColor'] as String?) ?? Colors.blue;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = index == selectedIndex;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? indicatorColor : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? indicatorColor : Colors.grey,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Custom navigation drawer with smooth animations
  static Widget buildAnimatedDrawer(Map<String, dynamic> properties, List<dynamic>? children) {
    final items = (properties['items'] as List?)?.map((e) => e['label'] as String? ?? 'Item').toList() ?? [];
    final isOpen = properties['isOpen'] as bool? ?? false;
    final animationDuration = Duration(milliseconds: (properties['animationDuration'] as num?)?.toInt() ?? 300);

    return AnimatedContainer(
      duration: animationDuration,
      width: isOpen ? 250 : 0,
      color: Colors.blue,
      child: isOpen
          ? ListView(
              children: items.map((item) {
                return ListTile(
                  title: Text(item, style: TextStyle(color: Colors.white)),
                  onTap: () {},
                );
              }).toList(),
            )
          : SizedBox.shrink(),
    );
  }

  /// Pagination navigation widget
  static Widget buildPaginationNav(Map<String, dynamic> properties, List<dynamic>? children) {
    final currentPage = (properties['currentPage'] as num?)?.toInt() ?? 1;
    final totalPages = (properties['totalPages'] as num?)?.toInt() ?? 5;
    final maxButtons = (properties['maxButtons'] as num?)?.toInt() ?? 5;
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.white;

    final startPage = ((currentPage - 1) ~/ maxButtons) * maxButtons + 1;
    final endPage = (startPage + maxButtons - 1).clamp(0, totalPages);

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentPage > 1)
            ElevatedButton(
              onPressed: () {},
              child: Text('← Previous'),
            ),
          SizedBox(width: 8),
          ...List.generate(endPage - startPage + 1, (index) {
            final pageNum = startPage + index;
            final isActive = pageNum == currentPage;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.blue : Colors.grey[300],
                ),
                child: Text(
                  '$pageNum',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
          SizedBox(width: 8),
          if (currentPage < totalPages)
            ElevatedButton(
              onPressed: () {},
              child: Text('Next →'),
            ),
        ],
      ),
    );
  }

  // Helper methods
  static IconData _parseIcon(String? iconName) {
    final iconMap = {
      'home': Icons.home,
      'search': Icons.search,
      'person': Icons.person,
      'settings': Icons.settings,
      'favorite': Icons.favorite,
      'shopping_cart': Icons.shopping_cart,
      'menu': Icons.menu,
      'more': Icons.more_vert,
      'notifications': Icons.notifications,
      'account': Icons.account_circle,
    };
    return iconMap[iconName?.toLowerCase()] ?? Icons.circle;
  }

  static Color? _parseColor(String? colorHex) {
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }
}

/// Support classes for navigation widgets
class BreadcrumbItem {
  final String label;
  final bool isClickable;

  BreadcrumbItem({required this.label, required this.isClickable});
}

class MenuBarItem {
  final String label;
  final List<String> subItems;

  MenuBarItem({required this.label, required this.subItems});
}

class SideBarItem {
  final String label;
  final bool expanded;
  final List<String> subItems;

  SideBarItem({required this.label, required this.expanded, required this.subItems});
}

class BottomNavItem {
  final String label;
  final IconData icon;
  final String? badge;

  BottomNavItem({required this.label, required this.icon, this.badge});
}
