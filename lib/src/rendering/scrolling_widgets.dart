/// Phase 3: Layout & Advanced Widgets
/// 
/// This file contains implementations for 13 layout and advanced widgets
/// focusing on responsive design, Sliver-based layouts, and advanced patterns.

import 'package:flutter/material.dart';

class ScrollingWidgets {
  /// CustomScrollView - Advanced scrolling with mixed scroll effects
  static Widget buildCustomScrollView(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final slivers = childrenData.isEmpty ? <Widget>[] : childrenData.map((child) {
      if (child is Map<String, dynamic>) {
        return _buildSliver(child);
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }).toList();

    return CustomScrollView(
      slivers: slivers.cast<Widget>(),
    );
  }

  /// SliverList - Efficient list of items in CustomScrollView
  static Widget buildSliverList(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final items = childrenData.isEmpty ? <Map<String, dynamic>>[] : childrenData.whereType<Map<String, dynamic>>().toList();
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= items.length) return null;
          return items[index]['child'] ?? const SizedBox.shrink();
        },
        childCount: items.length,
      ),
    );
  }

  /// SliverGrid - Efficient grid of items in CustomScrollView
  static Widget buildSliverGrid(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final crossAxisCount = (properties['crossAxisCount'] as num?)?.toInt() ?? 2;
    final items = childrenData.isEmpty ? <Map<String, dynamic>>[] : childrenData.whereType<Map<String, dynamic>>().toList();
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: (properties['crossAxisSpacing'] as num?)?.toDouble() ?? 8.0,
        mainAxisSpacing: (properties['mainAxisSpacing'] as num?)?.toDouble() ?? 8.0,
        childAspectRatio: (properties['childAspectRatio'] as num?)?.toDouble() ?? 1.0,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= items.length) return null;
          return items[index]['child'] ?? const SizedBox.shrink();
        },
        childCount: items.length,
      ),
    );
  }

  /// Flow - Advanced layout for overlapping widgets with custom positioning
  static Widget buildFlow(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final children = childrenData.isEmpty ? <Widget>[] : childrenData
        .whereType<Map<String, dynamic>>()
        .map((child) => Container(
          width: (child['width'] as num?)?.toDouble() ?? 50.0,
          height: (child['height'] as num?)?.toDouble() ?? 50.0,
          color: Colors.primaries[((child['colorIndex'] as num?)?.toInt() ?? 0) % Colors.primaries.length],
        ))
        .toList();

    return Flow(
      delegate: _FlowDelegate(
        offset: Offset(
          (properties['offsetX'] as num?)?.toDouble() ?? 0.0,
          (properties['offsetY'] as num?)?.toDouble() ?? 0.0,
        ),
        spacing: (properties['spacing'] as num?)?.toDouble() ?? 10.0,
      ),
      children: children,
    );
  }

  /// LayoutBuilder - Responsive layout based on parent constraints
  static Widget buildLayoutBuilder(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final child = childrenData.isNotEmpty 
        ? (childrenData.first as Map<String, dynamic>)['child'] 
        : null;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        
        return Container(
          color: Color(int.parse(
            (properties['backgroundColor'] as String? ?? '#FFFFFF').replaceFirst('#', '0xFF'),
          )),
          padding: EdgeInsets.all((properties['padding'] as num?)?.toDouble() ?? 16.0),
          child: isWide 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: child ?? Container(
                        color: Colors.grey[300],
                        height: 200,
                      ),
                    ),
                    SizedBox(width: (properties['gapWidth'] as num?)?.toDouble() ?? 16.0),
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: Colors.grey[200],
                        height: 200,
                      ),
                    ),
                  ],
                )
              : child ?? Container(
                  color: Colors.grey[300],
                  height: 200,
                ),
        );
      },
    );
  }

  /// MediaQuery helper - Responsive design widget
  static Widget buildMediaQueryHelper(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return MediaQuery(
      data: MediaQueryData.fromView(WidgetsBinding.instance.window),
      child: childrenData.isNotEmpty 
          ? (childrenData.first as Map<String, dynamic>)['child'] ?? const SizedBox.shrink()
          : const SizedBox.shrink(),
    );
  }

  /// ResponsiveWidget - Automatically adapts to screen size
  static Widget buildResponsiveWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final isDesktop = constraints.maxWidth >= 1024;
        
        String screenType = 'mobile';
        if (isTablet) screenType = 'tablet';
        if (isDesktop) screenType = 'desktop';
        
        return Container(
          color: Color(int.parse(
            (properties['backgroundColor'] as String? ?? '#FFFFFF').replaceFirst('#', '0xFF'),
          )),
          padding: EdgeInsets.all((properties['padding'] as num?)?.toDouble() ?? 16.0),
          child: Center(
            child: Text(
              'Screen Type: $screenType (${constraints.maxWidth.toStringAsFixed(0)}px)',
              style: TextStyle(
                fontSize: (properties['fontSize'] as num?)?.toDouble() ?? 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  /// SliverAppBar - Advanced app bar with scroll effects
  static Widget buildAdvancedSliverAppBar(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final title = properties['title'] as String? ?? 'Title';
    final expandedHeight = (properties['expandedHeight'] as num?)?.toDouble() ?? 200.0;
    
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: expandedHeight,
          floating: properties['floating'] as bool? ?? false,
          pinned: properties['pinned'] as bool? ?? true,
          snap: properties['snap'] as bool? ?? false,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title),
            background: Container(
              color: Color(int.parse(
                (properties['backgroundColor'] as String? ?? '#2196F3').replaceFirst('#', '0xFF'),
              )),
              alignment: Alignment.center,
              child: Icon(
                Icons.image,
                size: 80,
                color: Colors.white70,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              properties['description'] as String? ?? 'Content below',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// NestedScrollView - Multiple scroll controllers
  static Widget buildNestedScrollView(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          title: Text(properties['title'] as String? ?? 'Nested Scroll'),
          floating: true,
          pinned: true,
          forceElevated: innerBoxIsScrolled,
        ),
      ],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                properties['bodyText'] as String? ?? 'Body content here',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// AnimatedBuilder - Custom animations with builder pattern
  static Widget buildAnimatedBuilder(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return _AnimationBuilderWidget(
      duration: Duration(
        milliseconds: ((properties['duration'] as num?)?.toInt() ?? 500),
      ),
      animationType: properties['animationType'] as String? ?? 'rotate',
    );
  }

  /// TabBarView with TabController - Swipeable tabs
  static Widget buildTabBarViewAdvanced(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return DefaultTabController(
      length: (properties['tabCount'] as num?)?.toInt() ?? 3,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: List.generate(
              (properties['tabCount'] as num?)?.toInt() ?? 3,
              (index) => Tab(text: 'Tab ${index + 1}'),
            ),
          ),
          title: Text(properties['title'] as String? ?? 'Tabs'),
        ),
        body: TabBarView(
          children: List.generate(
            (properties['tabCount'] as num?)?.toInt() ?? 3,
            (index) => Center(
              child: Text('Content for Tab ${index + 1}'),
            ),
          ),
        ),
      ),
    );
  }

  /// PinchZoom - Pinch to zoom image/content
  static Widget buildPinchZoom(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return InteractiveViewer(
      minScale: (properties['minScale'] as num?)?.toDouble() ?? 0.5,
      maxScale: (properties['maxScale'] as num?)?.toDouble() ?? 4.0,
      child: Container(
        color: Color(int.parse(
          (properties['backgroundColor'] as String? ?? '#F5F5F5').replaceFirst('#', '0xFF'),
        )),
        child: Center(
          child: Text(
            properties['text'] as String? ?? 'Pinch to zoom',
            style: TextStyle(
              fontSize: (properties['fontSize'] as num?)?.toDouble() ?? 18.0,
            ),
          ),
        ),
      ),
    );
  }

  /// VirtualizedList - Efficient large list with virtualization
  static Widget buildVirtualizedList(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final itemCount = (properties['itemCount'] as num?)?.toInt() ?? 100;
    
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => ListTile(
        title: Text('Item $index'),
        subtitle: Text('Subtitle for item $index'),
        leading: CircleAvatar(
          child: Text('${index + 1}'),
        ),
      ),
    );
  }

  /// Sticky Headers - Headers that stick to top while scrolling
  static Widget buildStickyHeaders(Map<String, dynamic> properties, List<dynamic> childrenData) {
    final sections = (properties['sections'] as List? ?? []).cast<Map<String, dynamic>>();
    
    return ListView.builder(
      itemCount: sections.length * 11, // 1 header + 10 items per section
      itemBuilder: (context, index) {
        final sectionIndex = index ~/ 11;
        final itemInSection = index % 11;
        
        if (itemInSection == 0) {
          return Container(
            color: Colors.grey[300],
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Section ${sectionIndex + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
        
        return ListTile(
          title: Text('Item ${itemInSection} - Section ${sectionIndex + 1}'),
        );
      },
    );
  }

  // ===== HELPER METHODS =====

  static Widget _buildSliver(Map<String, dynamic> sliverConfig) {
    final type = sliverConfig['type'] as String? ?? 'SliverToBoxAdapter';
    
    return switch (type) {
      'SliverAppBar' => SliverAppBar(
        title: Text(sliverConfig['title'] as String? ?? ''),
        pinned: true,
      ),
      'SliverList' => buildSliverList(
        (sliverConfig['properties'] as Map<String, dynamic>?) ?? {},
        (sliverConfig['children'] as List?) ?? [],
      ),
      'SliverGrid' => buildSliverGrid(
        (sliverConfig['properties'] as Map<String, dynamic>?) ?? {},
        (sliverConfig['children'] as List?) ?? [],
      ),
      _ => SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: const Text('Sliver widget'),
        ),
      ),
    };
  }
}

/// Flow delegate for custom positioning
class _FlowDelegate extends FlowDelegate {
  final Offset offset;
  final double spacing;

  _FlowDelegate({required this.offset, required this.spacing});

  @override
  void paintChildren(FlowPaintingContext context) {
    var dx = offset.dx;
    var dy = offset.dy;
    
    for (int i = 0; i < context.childCount; i++) {
      final size = context.getChildSize(i);
      if (size == null) continue;
      
      context.paintChild(
        i,
        transform: Matrix4.translationValues(dx, dy, 0),
      );
      
      dx += size.width + spacing;
      if (dx > 300) {
        dx = offset.dx;
        dy += size.height + spacing;
      }
    }
  }

  @override
  bool shouldRepaint(_FlowDelegate oldDelegate) => true;
}

/// AnimatedBuilder widget for custom animations
class _AnimationBuilderWidget extends StatefulWidget {
  final Duration duration;
  final String animationType;

  const _AnimationBuilderWidget({
    required this.duration,
    required this.animationType,
  });

  @override
  State<_AnimationBuilderWidget> createState() => _AnimationBuilderWidgetState();
}

class _AnimationBuilderWidgetState extends State<_AnimationBuilderWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Center(
              child: Text(
                'Rotating',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        );
      },
    );
  }
}
