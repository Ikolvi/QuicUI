import 'package:flutter/material.dart';
import 'phase5_widgets.dart';

/// Phase 5 Examples - Animation & Transition Widget Usage
/// Demonstrates practical implementations of 25 animation effects

class Phase5Examples {
  /// Example: Fading UI element
  static Widget buildFadingUIExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedOpacity({'opacity': 0.5, 'duration': 800}, null),
        SizedBox(height: 16),
        Text('Fading Effect'),
      ],
    );
  }

  /// Example: Growing widget
  static Widget buildGrowingWidgetExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedScale({'scale': 1.5, 'duration': 1000}, null),
        SizedBox(height: 16),
        Text('Growing/Scaling'),
      ],
    );
  }

  /// Example: Spinning widget
  static Widget buildSpinningWidgetExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedRotation({'turns': 0.5, 'duration': 1500}, null),
        SizedBox(height: 16),
        Text('Spinning Animation'),
      ],
    );
  }

  /// Example: Animated card
  static Widget buildAnimatedCardExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedContainer({
          'width': 200,
          'height': 150,
          'duration': 800,
          'backgroundColor': '#3498db',
          'borderRadius': 12,
        }, null),
        SizedBox(height: 16),
        Text('Animated Card'),
      ],
    );
  }

  /// Example: Moving element with position animation
  static Widget buildMovingElementExample() {
    return Column(
      children: [
        Container(
          height: 200,
          width: 300,
          color: Colors.grey[100],
          child: Phase5Widgets.buildAnimatedPositioned({
            'left': 50,
            'top': 75,
          }, null),
        ),
        Text('Position Animation'),
      ],
    );
  }

  /// Example: Align animation
  static Widget buildAlignmentAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedAlign({'alignment': 'bottomRight', 'duration': 800}, null),
        SizedBox(height: 16),
        Text('Alignment Animation'),
      ],
    );
  }

  /// Example: Hero animation (shared element)
  static Widget buildHeroAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildHero({'tag': 'hero-example', 'heroSize': 100}, null),
        SizedBox(height: 16),
        Text('Hero Animation'),
      ],
    );
  }

  /// Example: Value tween animation
  static Widget buildValueTweenExample() {
    return Column(
      children: [
        Phase5Widgets.buildTweenAnimationBuilder({
          'startValue': 0,
          'endValue': 200,
          'duration': 2000,
        }, null),
        SizedBox(height: 16),
        Text('Tween Animation'),
      ],
    );
  }

  /// Example: Text style animation
  static Widget buildTextStyleAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedDefaultTextStyle({
          'fontSize': 32,
          'fontWeight': 'bold',
          'duration': 800,
          'textColor': '#e74c3c',
        }, null),
        SizedBox(height: 16),
        Text('Text Style Animation'),
      ],
    );
  }

  /// Example: Elevation animation (3D effect)
  static Widget buildElevationAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedPhysicalModel({
          'elevation': 16,
          'duration': 800,
          'shadowColor': '#000000',
        }, null),
        SizedBox(height: 16),
        Text('Elevation Animation'),
      ],
    );
  }

  /// Example: Widget switching animation
  static Widget buildWidgetSwitchingExample() {
    return Column(
      children: [
        Phase5Widgets.buildAnimatedSwitcher({
          'duration': 500,
          'transitionBuilder': 'scale',
        }, null),
        SizedBox(height: 16),
        Text('Switcher Animation'),
      ],
    );
  }

  /// Example: Slide animation
  static Widget buildSlideAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildSlideAnimation({'slideX': 50, 'slideY': 0}, null),
        SizedBox(height: 16),
        Text('Slide Animation'),
      ],
    );
  }

  /// Example: Fade in/out
  static Widget buildFadeInOutExample() {
    return Column(
      children: [
        Phase5Widgets.buildFadeAnimation({'opacity': 0.3}, null),
        SizedBox(height: 16),
        Text('Fade In/Out'),
      ],
    );
  }

  /// Example: Smooth rotation
  static Widget buildSmoothRotationExample() {
    return Column(
      children: [
        Phase5Widgets.buildRotationAnimation({'angle': 0.785}, null),
        SizedBox(height: 16),
        Text('Rotation (45°)'),
      ],
    );
  }

  /// Example: Size scaling
  static Widget buildSizeScalingExample() {
    return Column(
      children: [
        Phase5Widgets.buildScaleAnimation({'scale': 1.3}, null),
        SizedBox(height: 16),
        Text('Size Scaling'),
      ],
    );
  }

  /// Example: Perspective transform
  static Widget buildPerspectiveExample() {
    return Column(
      children: [
        Phase5Widgets.buildPerspectiveAnimation({'perspective': 0.003}, null),
        SizedBox(height: 16),
        Text('3D Perspective'),
      ],
    );
  }

  /// Example: Shake effect
  static Widget buildShakeEffectExample() {
    return Column(
      children: [
        Phase5Widgets.buildShakeAnimation({'intensity': 8}, null),
        SizedBox(height: 16),
        Text('Shake Effect'),
      ],
    );
  }

  /// Example: Pulse animation
  static Widget buildPulseEffectExample() {
    return Column(
      children: [
        Phase5Widgets.buildPulseAnimation({'maxScale': 1.3}, null),
        SizedBox(height: 16),
        Text('Pulse Effect'),
      ],
    );
  }

  /// Example: Float/levitate effect
  static Widget buildFloatEffectExample() {
    return Column(
      children: [
        Phase5Widgets.buildFloatingAnimation({'floatDistance': 15}, null),
        SizedBox(height: 16),
        Text('Floating Effect'),
      ],
    );
  }

  /// Example: Glow effect
  static Widget buildGlowEffectExample() {
    return Column(
      children: [
        Phase5Widgets.buildGlowAnimation({'glowRadius': 15, 'glowColor': '#3498db'}, null),
        SizedBox(height: 16),
        Text('Glow Effect'),
      ],
    );
  }

  /// Example: Progress animation
  static Widget buildProgressAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildProgressAnimation({'progress': 0.65}, null),
        SizedBox(height: 16),
        Text('Progress Animation'),
      ],
    );
  }

  /// Example: Wave animation
  static Widget buildWaveAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildWaveAnimation({'waveHeight': 15}, null),
        SizedBox(height: 16),
        Text('Wave Effect'),
      ],
    );
  }

  /// Example: Color transition
  static Widget buildColorTransitionExample() {
    return Column(
      children: [
        Phase5Widgets.buildColorAnimation({
          'startColor': '#ff6b6b',
          'endColor': '#4ecdc4',
        }, null),
        SizedBox(height: 16),
        Text('Color Transition'),
      ],
    );
  }

  /// Example: Blur animation
  static Widget buildBlurAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildBlurAnimation({'blurRadius': 8}, null),
        SizedBox(height: 16),
        Text('Blur Effect'),
      ],
    );
  }

  /// Example: Combined animations dashboard
  static Widget buildAnimationDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phase 5: Animation Widgets Showcase', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 24),
            
            // Grid layout for animations
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                buildAnimationCard('Opacity', buildFadingUIExample()),
                buildAnimationCard('Scale', buildGrowingWidgetExample()),
                buildAnimationCard('Rotation', buildSpinningWidgetExample()),
                buildAnimationCard('Container', buildAnimatedCardExample()),
                buildAnimationCard('Position', buildMovingElementExample()),
                buildAnimationCard('Alignment', buildAlignmentAnimationExample()),
                buildAnimationCard('Hero', buildHeroAnimationExample()),
                buildAnimationCard('Tween', buildValueTweenExample()),
                buildAnimationCard('TextStyle', buildTextStyleAnimationExample()),
                buildAnimationCard('Elevation', buildElevationAnimationExample()),
                buildAnimationCard('Switcher', buildWidgetSwitchingExample()),
                buildAnimationCard('Slide', buildSlideAnimationExample()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to build animation demo cards
  static Widget buildAnimationCard(String title, Widget content) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(child: content),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  /// Example: Loading animation sequence
  static Widget buildLoadingSequenceExample() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Phase5Widgets.buildPulseAnimation({'maxScale': 1.2}, null),
        SizedBox(height: 16),
        Phase5Widgets.buildProgressAnimation({'progress': 0.75}, null),
        SizedBox(height: 24),
        Text('Loading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Example: Button press animation
  static Widget buildButtonPressAnimationExample() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Phase5Widgets.buildAnimatedScale({'scale': 0.95, 'duration': 200}, null),
          SizedBox(height: 24),
          Text('Pressable Button', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Example: Card flip animation
  static Widget buildCardFlipAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildFlipAnimation({'angle': 1.57}, null),
        SizedBox(height: 16),
        Text('Card Flip (90°)'),
      ],
    );
  }

  /// Example: Bounce animation
  static Widget buildBounceAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildBounceAnimation({'bounceHeight': 25}, null),
        SizedBox(height: 16),
        Text('Bounce Effect'),
      ],
    );
  }

  /// Example: Skew animation
  static Widget buildSkewAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildSkewAnimation({'skewX': 0.2}, null),
        SizedBox(height: 16),
        Text('Skew Transform'),
      ],
    );
  }

  /// Example: Size animation
  static Widget buildSizeAnimationExample() {
    return Column(
      children: [
        Phase5Widgets.buildSizeAnimation({'width': 120, 'height': 120}, null),
        SizedBox(height: 16),
        Text('Size Animation'),
      ],
    );
  }
}
