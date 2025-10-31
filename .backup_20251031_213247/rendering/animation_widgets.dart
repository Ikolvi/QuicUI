import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Phase 5: Animation & Transition Widgets - Advanced motion effects and animations
/// Includes implicit animations, explicit transitions, hero animations, and custom animations
/// Note: Does NOT duplicate existing animation widgets

class AnimationWidgets {
  /// AnimatedOpacity with custom duration and curve
  static Widget buildAnimatedOpacity(Map<String, dynamic> properties, List<dynamic>? children) {
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 1.0;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final curve = _parseCurve(properties['curve'] as String? ?? 'easeInOut');

    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: curve,
      child: Container(color: Colors.blue, height: 100, width: 100),
    );
  }

  /// AnimatedScale with smooth size transitions
  static Widget buildAnimatedScale(Map<String, dynamic> properties, List<dynamic>? children) {
    final scale = (properties['scale'] as num?)?.toDouble() ?? 1.0;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final curve = _parseCurve(properties['curve'] as String? ?? 'easeInOut');

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      child: Container(width: 100, height: 100, color: Colors.green),
    );
  }

  /// AnimatedRotation with 360-degree rotation
  static Widget buildAnimatedRotation(Map<String, dynamic> properties, List<dynamic>? children) {
    final turns = (properties['turns'] as num?)?.toDouble() ?? 1.0;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final curve = _parseCurve(properties['curve'] as String? ?? 'easeInOut');

    return AnimatedRotation(
      turns: turns,
      duration: duration,
      curve: curve,
      child: Container(width: 100, height: 100, color: Colors.red),
    );
  }

  /// AnimatedPositioned for animating position changes
  static Widget buildAnimatedPositioned(Map<String, dynamic> properties, List<dynamic>? children) {
    final left = (properties['left'] as num?)?.toDouble() ?? 0;
    final top = (properties['top'] as num?)?.toDouble() ?? 0;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final curve = _parseCurve(properties['curve'] as String? ?? 'easeInOut');

    return Stack(
      children: [
        AnimatedPositioned(
          left: left,
          top: top,
          duration: duration,
          curve: curve,
          child: Container(width: 50, height: 50, color: Colors.purple),
        ),
      ],
    );
  }

  /// AnimatedAlign for animated alignment changes
  static Widget buildAnimatedAlign(Map<String, dynamic> properties, List<dynamic>? children) {
    final alignment = _parseAlignment(properties['alignment'] as String? ?? 'center');
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final curve = _parseCurve(properties['curve'] as String? ?? 'easeInOut');

    return Container(
      width: 300,
      height: 300,
      color: Colors.grey[200],
      child: AnimatedAlign(
        alignment: alignment,
        duration: duration,
        curve: curve,
        child: Container(width: 50, height: 50, color: Colors.orange),
      ),
    );
  }

  /// Hero animation for shared element transitions
  static Widget buildHero(Map<String, dynamic> properties, List<dynamic>? children) {
    final tag = properties['tag'] as String? ?? 'hero';
    final heroSize = (properties['heroSize'] as num?)?.toDouble() ?? 100;

    return Hero(
      tag: tag,
      child: Container(
        width: heroSize,
        height: heroSize,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// TweenAnimationBuilder for custom animations
  static Widget buildTweenAnimationBuilder(Map<String, dynamic> properties, List<dynamic>? children) {
    final startValue = (properties['startValue'] as num?)?.toDouble() ?? 0.0;
    final endValue = (properties['endValue'] as num?)?.toDouble() ?? 100.0;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 1000);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: startValue, end: endValue),
      duration: duration,
      builder: (context, value, child) {
        return Container(
          width: value,
          height: 100,
          color: Colors.green,
          child: Center(child: Text('${value.toStringAsFixed(0)}')),
        );
      },
    );
  }

  /// AnimatedContainer for multi-property animations
  static Widget buildAnimatedContainer(Map<String, dynamic> properties, List<dynamic>? children) {
    final width = (properties['width'] as num?)?.toDouble() ?? 100;
    final height = (properties['height'] as num?)?.toDouble() ?? 100;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final backgroundColor = _parseColor(properties['backgroundColor'] as String?) ?? Colors.blue;
    final borderRadius = (properties['borderRadius'] as num?)?.toDouble() ?? 0;

    return AnimatedContainer(
      width: width,
      height: height,
      duration: duration,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// AnimatedDefaultTextStyle for text animation
  static Widget buildAnimatedDefaultTextStyle(Map<String, dynamic> properties, List<dynamic>? children) {
    final fontSize = (properties['fontSize'] as num?)?.toDouble() ?? 20;
    final fontWeight = properties['fontWeight'] as String? ?? 'normal';
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final textColor = _parseColor(properties['textColor'] as String?) ?? Colors.black;

    return AnimatedDefaultTextStyle(
      duration: duration,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: _parseFontWeight(fontWeight),
        color: textColor,
      ),
      child: Text('Animated Text'),
    );
  }

  /// AnimatedPhysicalModel for elevation and shadow animations
  static Widget buildAnimatedPhysicalModel(Map<String, dynamic> properties, List<dynamic>? children) {
    final elevation = (properties['elevation'] as num?)?.toDouble() ?? 8;
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final shadowColor = _parseColor(properties['shadowColor'] as String?) ?? Colors.black;

    return AnimatedPhysicalModel(
      duration: duration,
      elevation: elevation,
      shadowColor: shadowColor,
      color: Colors.white,
      shape: BoxShape.rectangle,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.blue,
      ),
    );
  }

  /// AnimatedSwitcher for switching between widgets
  static Widget buildAnimatedSwitcher(Map<String, dynamic> properties, List<dynamic>? children) {
    final duration = Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 500);
    final transitionBuilder = properties['transitionBuilder'] as String? ?? 'fade';
    
    final widget = Container(width: 100, height: 100, color: Colors.blue);

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        if (transitionBuilder == 'scale') {
          return ScaleTransition(scale: animation, child: child);
        }
        return FadeTransition(opacity: animation, child: child);
      },
      child: widget,
    );
  }

  /// SlideAnimation using Transform
  static Widget buildSlideAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final slideX = (properties['slideX'] as num?)?.toDouble() ?? 0.0;
    final slideY = (properties['slideY'] as num?)?.toDouble() ?? 0.0;

    return Transform.translate(
      offset: Offset(slideX, slideY),
      child: Container(width: 100, height: 100, color: Colors.blue),
    );
  }

  /// FadeAnimation using Opacity
  static Widget buildFadeAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final opacity = (properties['opacity'] as num?)?.toDouble() ?? 0.5;

    return Opacity(
      opacity: opacity,
      child: Container(width: 100, height: 100, color: Colors.red),
    );
  }

  /// RotationAnimation using Transform.rotate
  static Widget buildRotationAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final angle = (properties['angle'] as num?)?.toDouble() ?? 0.0;

    return Transform.rotate(
      angle: angle,
      child: Container(width: 100, height: 100, color: Colors.green),
    );
  }

  /// ScaleAnimation using Transform.scale
  static Widget buildScaleAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final scale = (properties['scale'] as num?)?.toDouble() ?? 1.0;

    return Transform.scale(
      scale: scale,
      child: Container(width: 100, height: 100, color: Colors.purple),
    );
  }

  /// SizeAnimation using ConstrainedBox
  static Widget buildSizeAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final width = (properties['width'] as num?)?.toDouble() ?? 100;
    final height = (properties['height'] as num?)?.toDouble() ?? 100;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: width,
        minHeight: height,
        maxWidth: width * 2,
        maxHeight: height * 2,
      ),
      child: Container(color: Colors.orange),
    );
  }

  /// SkewAnimation using Transform Matrix
  static Widget buildSkewAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final skewX = (properties['skewX'] as num?)?.toDouble() ?? 0.0;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(1, 0, skewX),
      child: Container(width: 100, height: 100, color: Colors.pink),
    );
  }

  /// PerspectiveAnimation for 3D effects
  static Widget buildPerspectiveAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final perspective = (properties['perspective'] as num?)?.toDouble() ?? 0.003;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(3, 2, perspective),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.teal,
        child: Center(child: Icon(Icons.star, color: Colors.white)),
      ),
    );
  }

  /// ShakeAnimation for vibration effects
  static Widget buildShakeAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final intensity = (properties['intensity'] as num?)?.toDouble() ?? 5.0;

    return Transform.translate(
      offset: Offset(intensity, 0),
      child: Container(width: 100, height: 100, color: Colors.indigo),
    );
  }

  /// PulseAnimation for emphasis
  static Widget buildPulseAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final maxScale = (properties['maxScale'] as num?)?.toDouble() ?? 1.2;

    return Transform.scale(
      scale: maxScale,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// FlipAnimation for card flip effects
  static Widget buildFlipAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final angle = (properties['angle'] as num?)?.toDouble() ?? 0.0;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: Container(
        width: 100,
        height: 100,
        color: Colors.deepOrange,
        child: Center(child: Icon(Icons.flip, color: Colors.white)),
      ),
    );
  }

  /// BounceAnimation for playful effects
  static Widget buildBounceAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final bounceHeight = (properties['bounceHeight'] as num?)?.toDouble() ?? 20.0;

    return Transform.translate(
      offset: Offset(0, -bounceHeight),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// FloatingAnimation for floating UI elements
  static Widget buildFloatingAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final floatDistance = (properties['floatDistance'] as num?)?.toDouble() ?? 10.0;

    return Transform.translate(
      offset: Offset(0, -floatDistance),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.cyan,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text('Floating', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// GlowAnimation for glowing effects
  static Widget buildGlowAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final glowRadius = (properties['glowRadius'] as num?)?.toDouble() ?? 10.0;
    final glowColor = _parseColor(properties['glowColor'] as String?) ?? Colors.blue;

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: glowColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.6),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  /// ProgressAnimation for progress indicators
  static Widget buildProgressAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final progress = (properties['progress'] as num?)?.toDouble() ?? 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ),
        SizedBox(height: 8),
        Text('${(progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  }

  /// WaveAnimation for wave effects
  static Widget buildWaveAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final waveHeight = (properties['waveHeight'] as num?)?.toDouble() ?? 10.0;

    return Container(
      height: 100,
      color: Colors.blue[50],
      child: Stack(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(waveHeight),
                topRight: Radius.circular(waveHeight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ColorAnimation for color transitions
  static Widget buildColorAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final startColor = _parseColor(properties['startColor'] as String?) ?? Colors.red;
    final endColor = _parseColor(properties['endColor'] as String?) ?? Colors.blue;

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: startColor, end: endColor),
      duration: Duration(milliseconds: 1000),
      builder: (context, color, child) {
        return Container(
          width: 100,
          height: 100,
          color: color,
        );
      },
    );
  }

  /// BlurAnimation for blur effects
  static Widget buildBlurAnimation(Map<String, dynamic> properties, List<dynamic>? children) {
    final blurRadius = (properties['blurRadius'] as num?)?.toDouble() ?? 5.0;

    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
      child: Container(width: 100, height: 100, color: Colors.red),
    );
  }

  // Helper methods
  static Curve _parseCurve(String? curveName) {
    final curves = {
      'linear': Curves.linear,
      'easein': Curves.easeIn,
      'easeout': Curves.easeOut,
      'easeinout': Curves.easeInOut,
      'bouncein': Curves.bounceIn,
      'bounceout': Curves.bounceOut,
      'bounceinout': Curves.bounceInOut,
      'elasticin': Curves.elasticIn,
      'elasticout': Curves.elasticOut,
      'elasticinout': Curves.elasticInOut,
    };
    return curves[curveName?.toLowerCase()] ?? Curves.easeInOut;
  }

  static Alignment _parseAlignment(String? alignmentName) {
    final alignments = {
      'topleft': Alignment.topLeft,
      'topcenter': Alignment.topCenter,
      'topright': Alignment.topRight,
      'centerleft': Alignment.centerLeft,
      'center': Alignment.center,
      'centerright': Alignment.centerRight,
      'bottomleft': Alignment.bottomLeft,
      'bottomcenter': Alignment.bottomCenter,
      'bottomright': Alignment.bottomRight,
    };
    return alignments[alignmentName?.toLowerCase()] ?? Alignment.center;
  }

  static Color? _parseColor(String? colorHex) {
    if (colorHex == null) return null;
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (e) {
      return null;
    }
  }

  static FontWeight _parseFontWeight(String? weight) {
    final weights = {
      'thin': FontWeight.w100,
      'extralight': FontWeight.w200,
      'light': FontWeight.w300,
      'normal': FontWeight.w400,
      'medium': FontWeight.w500,
      'semibold': FontWeight.w600,
      'bold': FontWeight.w700,
      'extrabold': FontWeight.w800,
      'black': FontWeight.w900,
    };
    return weights[weight?.toLowerCase()] ?? FontWeight.normal;
  }
}
