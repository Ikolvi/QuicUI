/// Phase 5 Schema Definitions - Animation & Transition Widgets
/// Validates JSON structure for all 25 animation widgets

class Phase5Schemas {
  /// Schema for AnimatedOpacity widget
  static final animatedOpacitySchema = {
    'type': 'object',
    'properties': {
      'opacity': {
        'type': 'number',
        'minimum': 0.0,
        'maximum': 1.0,
        'description': 'Opacity value from 0.0 to 1.0'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'curve': {
        'type': 'string',
        'enum': ['linear', 'easeIn', 'easeOut', 'easeInOut', 'bounceIn', 'bounceOut', 'bounceInOut', 'elasticIn', 'elasticOut', 'elasticInOut'],
        'description': 'Animation curve type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedScale widget
  static final animatedScaleSchema = {
    'type': 'object',
    'properties': {
      'scale': {
        'type': 'number',
        'minimum': 0.0,
        'description': 'Scale factor'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'curve': {
        'type': 'string',
        'enum': ['linear', 'easeIn', 'easeOut', 'easeInOut', 'bounceIn', 'bounceOut', 'bounceInOut', 'elasticIn', 'elasticOut', 'elasticInOut'],
        'description': 'Animation curve type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedRotation widget
  static final animatedRotationSchema = {
    'type': 'object',
    'properties': {
      'turns': {
        'type': 'number',
        'description': 'Number of full rotations (0-1 = 0-360 degrees)'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'curve': {
        'type': 'string',
        'enum': ['linear', 'easeIn', 'easeOut', 'easeInOut', 'bounceIn', 'bounceOut', 'bounceInOut', 'elasticIn', 'elasticOut', 'elasticInOut'],
        'description': 'Animation curve type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedPositioned widget
  static final animatedPositionedSchema = {
    'type': 'object',
    'properties': {
      'left': {
        'type': 'number',
        'description': 'Left position in pixels'
      },
      'top': {
        'type': 'number',
        'description': 'Top position in pixels'
      },
      'right': {
        'type': 'number',
        'description': 'Right position in pixels'
      },
      'bottom': {
        'type': 'number',
        'description': 'Bottom position in pixels'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'curve': {
        'type': 'string',
        'enum': ['linear', 'easeIn', 'easeOut', 'easeInOut', 'bounceIn', 'bounceOut', 'bounceInOut', 'elasticIn', 'elasticOut', 'elasticInOut'],
        'description': 'Animation curve type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedAlign widget
  static final animatedAlignSchema = {
    'type': 'object',
    'properties': {
      'alignment': {
        'type': 'string',
        'enum': ['topLeft', 'topCenter', 'topRight', 'centerLeft', 'center', 'centerRight', 'bottomLeft', 'bottomCenter', 'bottomRight'],
        'description': 'Target alignment'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'curve': {
        'type': 'string',
        'enum': ['linear', 'easeIn', 'easeOut', 'easeInOut', 'bounceIn', 'bounceOut', 'bounceInOut', 'elasticIn', 'elasticOut', 'elasticInOut'],
        'description': 'Animation curve type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for Hero widget
  static final heroSchema = {
    'type': 'object',
    'properties': {
      'tag': {
        'type': 'string',
        'description': 'Unique identifier for hero animation'
      },
      'heroSize': {
        'type': 'number',
        'minimum': 0,
        'description': 'Size of the hero widget'
      }
    },
    'required': ['tag'],
    'additionalProperties': false
  };

  /// Schema for TweenAnimationBuilder widget
  static final tweenAnimationBuilderSchema = {
    'type': 'object',
    'properties': {
      'startValue': {
        'type': 'number',
        'description': 'Starting animation value'
      },
      'endValue': {
        'type': 'number',
        'description': 'Ending animation value'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedContainer widget
  static final animatedContainerSchema = {
    'type': 'object',
    'properties': {
      'width': {
        'type': 'number',
        'minimum': 0,
        'description': 'Container width'
      },
      'height': {
        'type': 'number',
        'minimum': 0,
        'description': 'Container height'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'backgroundColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Background color in hex format'
      },
      'borderRadius': {
        'type': 'number',
        'minimum': 0,
        'description': 'Border radius in pixels'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedDefaultTextStyle widget
  static final animatedDefaultTextStyleSchema = {
    'type': 'object',
    'properties': {
      'fontSize': {
        'type': 'number',
        'minimum': 0,
        'description': 'Font size in pixels'
      },
      'fontWeight': {
        'type': 'string',
        'enum': ['thin', 'extralight', 'light', 'normal', 'medium', 'semibold', 'bold', 'extrabold', 'black'],
        'description': 'Font weight'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'textColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Text color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedPhysicalModel widget
  static final animatedPhysicalModelSchema = {
    'type': 'object',
    'properties': {
      'elevation': {
        'type': 'number',
        'minimum': 0,
        'description': 'Elevation/shadow depth'
      },
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'shadowColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Shadow color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for AnimatedSwitcher widget
  static final animatedSwitcherSchema = {
    'type': 'object',
    'properties': {
      'duration': {
        'type': 'integer',
        'minimum': 0,
        'description': 'Animation duration in milliseconds'
      },
      'transitionBuilder': {
        'type': 'string',
        'enum': ['fade', 'scale'],
        'description': 'Transition animation type'
      }
    },
    'additionalProperties': false
  };

  /// Schema for SlideAnimation widget
  static final slideAnimationSchema = {
    'type': 'object',
    'properties': {
      'slideX': {
        'type': 'number',
        'description': 'Horizontal slide distance'
      },
      'slideY': {
        'type': 'number',
        'description': 'Vertical slide distance'
      }
    },
    'additionalProperties': false
  };

  /// Schema for FadeAnimation widget
  static final fadeAnimationSchema = {
    'type': 'object',
    'properties': {
      'opacity': {
        'type': 'number',
        'minimum': 0.0,
        'maximum': 1.0,
        'description': 'Opacity value'
      }
    },
    'additionalProperties': false
  };

  /// Schema for RotationAnimation widget
  static final rotationAnimationSchema = {
    'type': 'object',
    'properties': {
      'angle': {
        'type': 'number',
        'description': 'Rotation angle in radians'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ScaleAnimation widget
  static final scaleAnimationSchema = {
    'type': 'object',
    'properties': {
      'scale': {
        'type': 'number',
        'minimum': 0,
        'description': 'Scale factor'
      }
    },
    'additionalProperties': false
  };

  /// Schema for SizeAnimation widget
  static final sizeAnimationSchema = {
    'type': 'object',
    'properties': {
      'width': {
        'type': 'number',
        'minimum': 0,
        'description': 'Target width'
      },
      'height': {
        'type': 'number',
        'minimum': 0,
        'description': 'Target height'
      }
    },
    'additionalProperties': false
  };

  /// Schema for SkewAnimation widget
  static final skewAnimationSchema = {
    'type': 'object',
    'properties': {
      'skewX': {
        'type': 'number',
        'description': 'Horizontal skew factor'
      },
      'skewY': {
        'type': 'number',
        'description': 'Vertical skew factor'
      }
    },
    'additionalProperties': false
  };

  /// Schema for PerspectiveAnimation widget
  static final perspectiveAnimationSchema = {
    'type': 'object',
    'properties': {
      'perspective': {
        'type': 'number',
        'description': 'Perspective transformation factor'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ShakeAnimation widget
  static final shakeAnimationSchema = {
    'type': 'object',
    'properties': {
      'intensity': {
        'type': 'number',
        'minimum': 0,
        'description': 'Shake intensity in pixels'
      }
    },
    'additionalProperties': false
  };

  /// Schema for PulseAnimation widget
  static final pulseAnimationSchema = {
    'type': 'object',
    'properties': {
      'maxScale': {
        'type': 'number',
        'minimum': 1,
        'description': 'Maximum scale factor'
      }
    },
    'additionalProperties': false
  };

  /// Schema for FlipAnimation widget
  static final flipAnimationSchema = {
    'type': 'object',
    'properties': {
      'angle': {
        'type': 'number',
        'description': 'Flip angle in radians'
      }
    },
    'additionalProperties': false
  };

  /// Schema for BounceAnimation widget
  static final bounceAnimationSchema = {
    'type': 'object',
    'properties': {
      'bounceHeight': {
        'type': 'number',
        'minimum': 0,
        'description': 'Bounce height in pixels'
      }
    },
    'additionalProperties': false
  };

  /// Schema for FloatingAnimation widget
  static final floatingAnimationSchema = {
    'type': 'object',
    'properties': {
      'floatDistance': {
        'type': 'number',
        'minimum': 0,
        'description': 'Floating distance in pixels'
      }
    },
    'additionalProperties': false
  };

  /// Schema for GlowAnimation widget
  static final glowAnimationSchema = {
    'type': 'object',
    'properties': {
      'glowRadius': {
        'type': 'number',
        'minimum': 0,
        'description': 'Glow blur radius'
      },
      'glowColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Glow color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ProgressAnimation widget
  static final progressAnimationSchema = {
    'type': 'object',
    'properties': {
      'progress': {
        'type': 'number',
        'minimum': 0,
        'maximum': 1,
        'description': 'Progress value from 0 to 1'
      }
    },
    'additionalProperties': false
  };

  /// Schema for WaveAnimation widget
  static final waveAnimationSchema = {
    'type': 'object',
    'properties': {
      'waveHeight': {
        'type': 'number',
        'minimum': 0,
        'description': 'Wave height in pixels'
      }
    },
    'additionalProperties': false
  };

  /// Schema for ColorAnimation widget
  static final colorAnimationSchema = {
    'type': 'object',
    'properties': {
      'startColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Starting color in hex format'
      },
      'endColor': {
        'type': 'string',
        'pattern': r'^#[0-9A-Fa-f]{6}$',
        'description': 'Ending color in hex format'
      }
    },
    'additionalProperties': false
  };

  /// Schema for BlurAnimation widget
  static final blurAnimationSchema = {
    'type': 'object',
    'properties': {
      'blurRadius': {
        'type': 'number',
        'minimum': 0,
        'description': 'Blur radius amount'
      }
    },
    'additionalProperties': false
  };

  /// Validate properties against Phase 5 widget schemas
  static bool validateAnimatedOpacity(Map<String, dynamic> properties) {
    return properties['opacity'] is num && 
           (properties['opacity'] as num) >= 0 && 
           (properties['opacity'] as num) <= 1;
  }

  static bool validateAnimatedScale(Map<String, dynamic> properties) {
    return properties['scale'] is num && (properties['scale'] as num) >= 0;
  }

  static bool validateAnimatedRotation(Map<String, dynamic> properties) {
    return properties['turns'] is num;
  }

  static bool validateAnimatedPositioned(Map<String, dynamic> properties) {
    return (properties['left'] is num || properties['left'] == null) &&
           (properties['top'] is num || properties['top'] == null);
  }

  static bool validateAnimatedAlign(Map<String, dynamic> properties) {
    return properties['alignment'] is String;
  }

  static bool validateHero(Map<String, dynamic> properties) {
    return properties['tag'] is String;
  }

  static bool validateTweenAnimationBuilder(Map<String, dynamic> properties) {
    return properties['startValue'] is num && properties['endValue'] is num;
  }

  static bool validateAnimatedContainer(Map<String, dynamic> properties) {
    return (properties['width'] is num || properties['width'] == null) &&
           (properties['height'] is num || properties['height'] == null);
  }

  static bool validateAnimatedDefaultTextStyle(Map<String, dynamic> properties) {
    return (properties['fontSize'] is num || properties['fontSize'] == null) &&
           (properties['textColor'] is String || properties['textColor'] == null);
  }

  static bool validateAnimatedPhysicalModel(Map<String, dynamic> properties) {
    return properties['elevation'] is num && (properties['elevation'] as num) >= 0;
  }

  static bool validateAnimatedSwitcher(Map<String, dynamic> properties) {
    return properties['duration'] is int;
  }

  static bool validateSlideAnimation(Map<String, dynamic> properties) {
    return (properties['slideX'] is num || properties['slideX'] == null) &&
           (properties['slideY'] is num || properties['slideY'] == null);
  }

  static bool validateFadeAnimation(Map<String, dynamic> properties) {
    return (properties['opacity'] is num || properties['opacity'] == null);
  }

  static bool validateRotationAnimation(Map<String, dynamic> properties) {
    return properties['angle'] is num;
  }

  static bool validateScaleAnimation(Map<String, dynamic> properties) {
    return properties['scale'] is num;
  }

  static bool validateSizeAnimation(Map<String, dynamic> properties) {
    return (properties['width'] is num || properties['width'] == null) &&
           (properties['height'] is num || properties['height'] == null);
  }

  static bool validateSkewAnimation(Map<String, dynamic> properties) {
    return properties['skewX'] is num;
  }

  static bool validatePerspectiveAnimation(Map<String, dynamic> properties) {
    return properties['perspective'] is num;
  }

  static bool validateShakeAnimation(Map<String, dynamic> properties) {
    return properties['intensity'] is num && (properties['intensity'] as num) >= 0;
  }

  static bool validatePulseAnimation(Map<String, dynamic> properties) {
    return properties['maxScale'] is num && (properties['maxScale'] as num) >= 1;
  }

  static bool validateFlipAnimation(Map<String, dynamic> properties) {
    return properties['angle'] is num;
  }

  static bool validateBounceAnimation(Map<String, dynamic> properties) {
    return properties['bounceHeight'] is num && (properties['bounceHeight'] as num) >= 0;
  }

  static bool validateFloatingAnimation(Map<String, dynamic> properties) {
    return properties['floatDistance'] is num && (properties['floatDistance'] as num) >= 0;
  }

  static bool validateGlowAnimation(Map<String, dynamic> properties) {
    return (properties['glowRadius'] is num || properties['glowRadius'] == null) &&
           (properties['glowColor'] is String || properties['glowColor'] == null);
  }

  static bool validateProgressAnimation(Map<String, dynamic> properties) {
    return properties['progress'] is num && 
           (properties['progress'] as num) >= 0 && 
           (properties['progress'] as num) <= 1;
  }

  static bool validateWaveAnimation(Map<String, dynamic> properties) {
    return properties['waveHeight'] is num && (properties['waveHeight'] as num) >= 0;
  }

  static bool validateColorAnimation(Map<String, dynamic> properties) {
    return (properties['startColor'] is String || properties['startColor'] == null) &&
           (properties['endColor'] is String || properties['endColor'] == null);
  }

  static bool validateBlurAnimation(Map<String, dynamic> properties) {
    return properties['blurRadius'] is num && (properties['blurRadius'] as num) >= 0;
  }
}
