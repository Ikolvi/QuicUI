// Phase 5 Examples - Animation & Transition Widget Usage
// Demonstrates practical implementations of 25 animation effects
// Pure JSON configuration format (no method calls)

class Phase5Examples {
  /// AnimatedOpacity Examples
  static final animatedOpacityExamples = [
    {
      'name': 'Fade In Effect',
      'type': 'AnimatedOpacityCustom',
      'properties': {
        'opacity': 1.0,
        'duration': 800
      }
    },
    {
      'name': 'Fade Out Effect',
      'type': 'AnimatedOpacityCustom',
      'properties': {
        'opacity': 0.0,
        'duration': 1000
      }
    },
    {
      'name': 'Semi-transparent',
      'type': 'AnimatedOpacityCustom',
      'properties': {
        'opacity': 0.5,
        'duration': 600
      }
    },
  ];

  /// AnimatedScale Examples
  static final animatedScaleExamples = [
    {
      'name': 'Growing Widget',
      'type': 'AnimatedScaleCustom',
      'properties': {
        'scale': 1.5,
        'duration': 1000
      }
    },
    {
      'name': 'Shrinking Widget',
      'type': 'AnimatedScaleCustom',
      'properties': {
        'scale': 0.5,
        'duration': 800
      }
    },
    {
      'name': 'Zoom Effect',
      'type': 'AnimatedScaleCustom',
      'properties': {
        'scale': 2.0,
        'duration': 1200
      }
    },
  ];

  /// AnimatedRotation Examples
  static final animatedRotationExamples = [
    {
      'name': 'Half Turn',
      'type': 'AnimatedRotationCustom',
      'properties': {
        'turns': 0.5,
        'duration': 1500
      }
    },
    {
      'name': 'Full Rotation',
      'type': 'AnimatedRotationCustom',
      'properties': {
        'turns': 1.0,
        'duration': 2000
      }
    },
    {
      'name': 'Quarter Turn',
      'type': 'AnimatedRotationCustom',
      'properties': {
        'turns': 0.25,
        'duration': 800
      }
    },
  ];

  /// AnimatedContainer Examples
  static final animatedContainerExamples = [
    {
      'name': 'Color Change Animation',
      'type': 'AnimatedContainerCustom',
      'properties': {
        'width': 200,
        'height': 150,
        'duration': 800,
        'backgroundColor': '#3498DB',
        'borderRadius': 12
      }
    },
    {
      'name': 'Size Growing',
      'type': 'AnimatedContainerCustom',
      'properties': {
        'width': 300,
        'height': 250,
        'duration': 1000,
        'backgroundColor': '#E74C3C',
        'borderRadius': 8
      }
    },
    {
      'name': 'Smooth Transition',
      'type': 'AnimatedContainerCustom',
      'properties': {
        'width': 150,
        'height': 100,
        'duration': 1200,
        'backgroundColor': '#2ECC71',
        'borderRadius': 16
      }
    },
  ];

  /// AnimatedPositioned Examples
  static final animatedPositionedExamples = [
    {
      'name': 'Position Move',
      'type': 'AnimatedPositionedCustom',
      'properties': {
        'left': 20,
        'top': 20,
        'duration': 1000
      }
    },
    {
      'name': 'Slide Down',
      'type': 'AnimatedPositionedCustom',
      'properties': {
        'left': 0,
        'top': 200,
        'duration': 1500
      }
    },
    {
      'name': 'Center Position',
      'type': 'AnimatedPositionedCustom',
      'properties': {
        'left': 100,
        'top': 100,
        'duration': 800
      }
    },
  ];

  /// AnimatedAlign Examples
  static final animatedAlignExamples = [
    {
      'name': 'Center Align',
      'type': 'AnimatedAlignCustom',
      'properties': {
        'alignment': 'center',
        'duration': 800
      }
    },
    {
      'name': 'Bottom Right',
      'type': 'AnimatedAlignCustom',
      'properties': {
        'alignment': 'bottomRight',
        'duration': 800
      }
    },
    {
      'name': 'Top Left',
      'type': 'AnimatedAlignCustom',
      'properties': {
        'alignment': 'topLeft',
        'duration': 1000
      }
    },
  ];

  /// Hero Animation Examples
  static final heroExamples = [
    {
      'name': 'Hero Image',
      'type': 'HeroCustom',
      'properties': {
        'tag': 'hero-image',
        'heroSize': 100
      }
    },
    {
      'name': 'Hero Avatar',
      'type': 'HeroCustom',
      'properties': {
        'tag': 'hero-avatar',
        'heroSize': 80
      }
    },
    {
      'name': 'Hero Icon',
      'type': 'HeroCustom',
      'properties': {
        'tag': 'hero-icon',
        'heroSize': 64
      }
    },
  ];

  /// TweenAnimationBuilder Examples
  static final tweenAnimationBuilderExamples = [
    {
      'name': 'Number Counter',
      'type': 'TweenAnimationBuilderCustom',
      'properties': {
        'duration': 2000,
        'startValue': 0,
        'endValue': 100
      }
    },
    {
      'name': 'Percentage Progress',
      'type': 'TweenAnimationBuilderCustom',
      'properties': {
        'duration': 1500,
        'startValue': 0,
        'endValue': 1.0
      }
    },
    {
      'name': 'Countdown',
      'type': 'TweenAnimationBuilderCustom',
      'properties': {
        'duration': 3000,
        'startValue': 10,
        'endValue': 0
      }
    },
  ];

  /// AnimatedDefaultTextStyle Examples
  static final animatedDefaultTextStyleExamples = [
    {
      'name': 'Bold Animation',
      'type': 'AnimatedDefaultTextStyleCustom',
      'properties': {
        'fontSize': 24,
        'fontWeight': 'bold',
        'color': '#333333',
        'duration': 800
      }
    },
    {
      'name': 'Color Fade',
      'type': 'AnimatedDefaultTextStyleCustom',
      'properties': {
        'fontSize': 20,
        'fontWeight': 'normal',
        'color': '#2196F3',
        'duration': 1000
      }
    },
    {
      'name': 'Size Change',
      'type': 'AnimatedDefaultTextStyleCustom',
      'properties': {
        'fontSize': 28,
        'fontWeight': 'w500',
        'color': '#FF6B6B',
        'duration': 1200
      }
    },
  ];

  /// AnimatedPhysicalModel Examples
  static final animatedPhysicalModelExamples = [
    {
      'name': 'Elevation Increase',
      'type': 'AnimatedPhysicalModelCustom',
      'properties': {
        'elevation': 8,
        'shadowColor': '#000000',
        'duration': 800
      }
    },
    {
      'name': 'Deep Shadow',
      'type': 'AnimatedPhysicalModelCustom',
      'properties': {
        'elevation': 16,
        'shadowColor': '#333333',
        'duration': 1000
      }
    },
    {
      'name': 'Light Shadow',
      'type': 'AnimatedPhysicalModelCustom',
      'properties': {
        'elevation': 2,
        'shadowColor': '#CCCCCC',
        'duration': 600
      }
    },
  ];

  /// AnimatedSwitcher Examples
  static final animatedSwitcherExamples = [
    {
      'name': 'Content Switch',
      'type': 'AnimatedSwitcherCustom',
      'properties': {
        'duration': 500,
        'transitionType': 'fade'
      }
    },
    {
      'name': 'Scale Transition',
      'type': 'AnimatedSwitcherCustom',
      'properties': {
        'duration': 800,
        'transitionType': 'scale'
      }
    },
    {
      'name': 'Slide Transition',
      'type': 'AnimatedSwitcherCustom',
      'properties': {
        'duration': 700,
        'transitionType': 'slide'
      }
    },
  ];

  /// SlideAnimation Examples
  static final slideAnimationExamples = [
    {
      'name': 'Slide Right',
      'type': 'SlideAnimation',
      'properties': {
        'slideX': 100,
        'slideY': 0,
        'duration': 800
      }
    },
    {
      'name': 'Slide Down',
      'type': 'SlideAnimation',
      'properties': {
        'slideX': 0,
        'slideY': 100,
        'duration': 1000
      }
    },
    {
      'name': 'Diagonal Slide',
      'type': 'SlideAnimation',
      'properties': {
        'slideX': 50,
        'slideY': 50,
        'duration': 1200
      }
    },
  ];

  /// FadeAnimation Examples
  static final fadeAnimationExamples = [
    {
      'name': 'Fade In',
      'type': 'FadeAnimation',
      'properties': {
        'opacity': 1.0,
        'duration': 1000
      }
    },
    {
      'name': 'Fade Out',
      'type': 'FadeAnimation',
      'properties': {
        'opacity': 0.0,
        'duration': 800
      }
    },
    {
      'name': 'Semi Fade',
      'type': 'FadeAnimation',
      'properties': {
        'opacity': 0.3,
        'duration': 1200
      }
    },
  ];

  /// RotationAnimation Examples
  static final rotationAnimationExamples = [
    {
      'name': 'Slow Spin',
      'type': 'RotationAnimation',
      'properties': {
        'angle': 3.14159,
        'duration': 2000
      }
    },
    {
      'name': 'Fast Spin',
      'type': 'RotationAnimation',
      'properties': {
        'angle': 6.28318,
        'duration': 800
      }
    },
    {
      'name': 'Quarter Turn',
      'type': 'RotationAnimation',
      'properties': {
        'angle': 1.5708,
        'duration': 600
      }
    },
  ];

  /// ScaleAnimation Examples
  static final scaleAnimationExamples = [
    {
      'name': 'Zoom In',
      'type': 'ScaleAnimation',
      'properties': {
        'scale': 2.0,
        'duration': 1000
      }
    },
    {
      'name': 'Zoom Out',
      'type': 'ScaleAnimation',
      'properties': {
        'scale': 0.5,
        'duration': 800
      }
    },
    {
      'name': 'Moderate Zoom',
      'type': 'ScaleAnimation',
      'properties': {
        'scale': 1.3,
        'duration': 1200
      }
    },
  ];

  /// SizeAnimation Examples
  static final sizeAnimationExamples = [
    {
      'name': 'Expand',
      'type': 'SizeAnimation',
      'properties': {
        'width': 300,
        'height': 200,
        'duration': 1000
      }
    },
    {
      'name': 'Contract',
      'type': 'SizeAnimation',
      'properties': {
        'width': 100,
        'height': 80,
        'duration': 800
      }
    },
    {
      'name': 'Smooth Resize',
      'type': 'SizeAnimation',
      'properties': {
        'width': 200,
        'height': 150,
        'duration': 1200
      }
    },
  ];

  /// SkewAnimation Examples
  static final skewAnimationExamples = [
    {
      'name': 'Skew Horizontal',
      'type': 'SkewAnimation',
      'properties': {
        'skewX': 0.2,
        'skewY': 0,
        'duration': 1000
      }
    },
    {
      'name': 'Skew Vertical',
      'type': 'SkewAnimation',
      'properties': {
        'skewX': 0,
        'skewY': 0.2,
        'duration': 1200
      }
    },
    {
      'name': 'Skew Both',
      'type': 'SkewAnimation',
      'properties': {
        'skewX': 0.15,
        'skewY': 0.15,
        'duration': 1500
      }
    },
  ];

  /// PerspectiveAnimation Examples
  static final perspectiveAnimationExamples = [
    {
      'name': 'Perspective Tilt',
      'type': 'PerspectiveAnimation',
      'properties': {
        'perspective': 0.003,
        'rotationX': 0.5,
        'duration': 1000
      }
    },
    {
      'name': 'Subtle Perspective',
      'type': 'PerspectiveAnimation',
      'properties': {
        'perspective': 0.001,
        'rotationX': 0.2,
        'duration': 1200
      }
    },
    {
      'name': 'Deep Perspective',
      'type': 'PerspectiveAnimation',
      'properties': {
        'perspective': 0.005,
        'rotationX': 0.8,
        'duration': 1500
      }
    },
  ];

  /// ShakeAnimation Examples
  static final shakeAnimationExamples = [
    {
      'name': 'Gentle Shake',
      'type': 'ShakeAnimation',
      'properties': {
        'intensity': 4,
        'duration': 400
      }
    },
    {
      'name': 'Strong Shake',
      'type': 'ShakeAnimation',
      'properties': {
        'intensity': 8,
        'duration': 600
      }
    },
    {
      'name': 'Vigorous Shake',
      'type': 'ShakeAnimation',
      'properties': {
        'intensity': 12,
        'duration': 800
      }
    },
  ];

  /// PulseAnimation Examples
  static final pulseAnimationExamples = [
    {
      'name': 'Subtle Pulse',
      'type': 'PulseAnimation',
      'properties': {
        'maxScale': 1.1,
        'duration': 1000
      }
    },
    {
      'name': 'Strong Pulse',
      'type': 'PulseAnimation',
      'properties': {
        'maxScale': 1.3,
        'duration': 1200
      }
    },
    {
      'name': 'Intense Pulse',
      'type': 'PulseAnimation',
      'properties': {
        'maxScale': 1.5,
        'duration': 1500
      }
    },
  ];

  /// FlipAnimation Examples
  static final flipAnimationExamples = [
    {
      'name': 'Flip Horizontal',
      'type': 'FlipAnimation',
      'properties': {
        'direction': 'horizontal',
        'duration': 1000
      }
    },
    {
      'name': 'Flip Vertical',
      'type': 'FlipAnimation',
      'properties': {
        'direction': 'vertical',
        'duration': 1200
      }
    },
    {
      'name': 'Quick Flip',
      'type': 'FlipAnimation',
      'properties': {
        'direction': 'horizontal',
        'duration': 600
      }
    },
  ];

  /// BounceAnimation Examples
  static final bounceAnimationExamples = [
    {
      'name': 'Light Bounce',
      'type': 'BounceAnimation',
      'properties': {
        'bounceHeight': 20,
        'duration': 800
      }
    },
    {
      'name': 'High Bounce',
      'type': 'BounceAnimation',
      'properties': {
        'bounceHeight': 50,
        'duration': 1200
      }
    },
    {
      'name': 'Extra High Bounce',
      'type': 'BounceAnimation',
      'properties': {
        'bounceHeight': 80,
        'duration': 1500
      }
    },
  ];

  /// FloatingAnimation Examples
  static final floatingAnimationExamples = [
    {
      'name': 'Gentle Float',
      'type': 'FloatingAnimation',
      'properties': {
        'floatDistance': 10,
        'duration': 1000
      }
    },
    {
      'name': 'Medium Float',
      'type': 'FloatingAnimation',
      'properties': {
        'floatDistance': 15,
        'duration': 1200
      }
    },
    {
      'name': 'High Float',
      'type': 'FloatingAnimation',
      'properties': {
        'floatDistance': 25,
        'duration': 1500
      }
    },
  ];

  /// GlowAnimation Examples
  static final glowAnimationExamples = [
    {
      'name': 'Blue Glow',
      'type': 'GlowAnimation',
      'properties': {
        'glowRadius': 10,
        'glowColor': '#2196F3',
        'duration': 1200
      }
    },
    {
      'name': 'Red Glow',
      'type': 'GlowAnimation',
      'properties': {
        'glowRadius': 15,
        'glowColor': '#F44336',
        'duration': 1500
      }
    },
    {
      'name': 'Green Glow',
      'type': 'GlowAnimation',
      'properties': {
        'glowRadius': 12,
        'glowColor': '#4CAF50',
        'duration': 1000
      }
    },
  ];

  /// ProgressAnimation Examples
  static final progressAnimationExamples = [
    {
      'name': 'Quarter Progress',
      'type': 'ProgressAnimation',
      'properties': {
        'progress': 0.25,
        'duration': 1000
      }
    },
    {
      'name': 'Half Progress',
      'type': 'ProgressAnimation',
      'properties': {
        'progress': 0.5,
        'duration': 1200
      }
    },
    {
      'name': 'Full Progress',
      'type': 'ProgressAnimation',
      'properties': {
        'progress': 1.0,
        'duration': 1500
      }
    },
  ];

  /// WaveAnimation Examples
  static final waveAnimationExamples = [
    {
      'name': 'Gentle Wave',
      'type': 'WaveAnimation',
      'properties': {
        'amplitude': 5,
        'frequency': 2,
        'duration': 1000
      }
    },
    {
      'name': 'Strong Wave',
      'type': 'WaveAnimation',
      'properties': {
        'amplitude': 10,
        'frequency': 3,
        'duration': 1200
      }
    },
    {
      'name': 'Intense Wave',
      'type': 'WaveAnimation',
      'properties': {
        'amplitude': 15,
        'frequency': 4,
        'duration': 1500
      }
    },
  ];

  /// ColorAnimation Examples
  static final colorAnimationExamples = [
    {
      'name': 'Blue to Green',
      'type': 'ColorAnimation',
      'properties': {
        'startColor': '#2196F3',
        'endColor': '#4CAF50',
        'duration': 1500
      }
    },
    {
      'name': 'Red to Yellow',
      'type': 'ColorAnimation',
      'properties': {
        'startColor': '#F44336',
        'endColor': '#FFEB3B',
        'duration': 1200
      }
    },
    {
      'name': 'Purple to Orange',
      'type': 'ColorAnimation',
      'properties': {
        'startColor': '#9C27B0',
        'endColor': '#FF9800',
        'duration': 1800
      }
    },
  ];

  /// BlurAnimation Examples
  static final blurAnimationExamples = [
    {
      'name': 'Blur In',
      'type': 'BlurAnimation',
      'properties': {
        'blurAmount': 10,
        'duration': 1000
      }
    },
    {
      'name': 'Blur Out',
      'type': 'BlurAnimation',
      'properties': {
        'blurAmount': 0,
        'duration': 1200
      }
    },
    {
      'name': 'Strong Blur',
      'type': 'BlurAnimation',
      'properties': {
        'blurAmount': 20,
        'duration': 1500
      }
    },
  ];

  /// Get all examples
  static final allExamples = {
    'AnimatedOpacityCustom': animatedOpacityExamples,
    'AnimatedScaleCustom': animatedScaleExamples,
    'AnimatedRotationCustom': animatedRotationExamples,
    'AnimatedContainerCustom': animatedContainerExamples,
    'AnimatedPositionedCustom': animatedPositionedExamples,
    'AnimatedAlignCustom': animatedAlignExamples,
    'HeroCustom': heroExamples,
    'TweenAnimationBuilderCustom': tweenAnimationBuilderExamples,
    'AnimatedDefaultTextStyleCustom': animatedDefaultTextStyleExamples,
    'AnimatedPhysicalModelCustom': animatedPhysicalModelExamples,
    'AnimatedSwitcherCustom': animatedSwitcherExamples,
    'SlideAnimation': slideAnimationExamples,
    'FadeAnimation': fadeAnimationExamples,
    'RotationAnimation': rotationAnimationExamples,
    'ScaleAnimation': scaleAnimationExamples,
    'SizeAnimation': sizeAnimationExamples,
    'SkewAnimation': skewAnimationExamples,
    'PerspectiveAnimation': perspectiveAnimationExamples,
    'ShakeAnimation': shakeAnimationExamples,
    'PulseAnimation': pulseAnimationExamples,
    'FlipAnimation': flipAnimationExamples,
    'BounceAnimation': bounceAnimationExamples,
    'FloatingAnimation': floatingAnimationExamples,
    'GlowAnimation': glowAnimationExamples,
    'ProgressAnimation': progressAnimationExamples,
    'WaveAnimation': waveAnimationExamples,
    'ColorAnimation': colorAnimationExamples,
    'BlurAnimation': blurAnimationExamples,
  };

  /// Get example by type and index
  static Map<String, dynamic>? getExample(String type, int index) {
    final examples = allExamples[type];
    if (examples != null && index >= 0 && index < examples.length) {
      return examples[index];
    }
    return null;
  }

  /// Get all example names by type
  static List<String> getExampleNames(String type) {
    final examples = allExamples[type];
    if (examples != null) {
      return examples.map((e) => e['name'] as String).toList();
    }
    return [];
  }
}
