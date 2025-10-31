import 'package:flutter/material.dart';
import 'parse_utils.dart';

/// Input Widget Builders
/// 
/// Extracted from UIRenderer, provides builders for all input-related widgets
/// including buttons (ElevatedButton, TextButton, etc.), text fields, checkboxes,
/// radios, switches, sliders, and dropdown buttons.
/// 
/// All methods are static and can be imported independently for use in other contexts.
/// 
/// Each builder accepts a [properties] map and optional [childrenData] and [context].
/// Uses [ParseUtils] for all parsing operations (colors, text styles, etc.)
class InputWidgets {
  InputWidgets._(); // Private constructor - static methods only

  // ===== BUTTON WIDGETS =====

  /// Builds an ElevatedButton widget
  /// 
  /// Properties:
  /// - label: String (button text)
  /// - backgroundColor: String (hex color)
  /// - foregroundColor: String (hex color)
  /// - events: Map with 'onPressed' callback
  static Widget buildElevatedButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
    Function(Map<String, dynamic>)? onCallback,
  }) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : Text(properties['label'] as String? ?? 'Button');

    return ElevatedButton(
      onPressed: () {
        if (onCallback != null) {
          onCallback(properties);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: ParseUtils.parseColor(properties['backgroundColor']),
        foregroundColor: ParseUtils.parseColor(properties['foregroundColor']),
      ),
      child: child,
    );
  }

  /// Builds a TextButton widget
  /// 
  /// Properties:
  /// - label: String (button text)
  /// - foregroundColor: String (hex color)
  /// - events: Map with 'onPressed' callback
  static Widget buildTextButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
    Function(Map<String, dynamic>)? onCallback,
  }) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : Text(properties['label'] as String? ?? 'Button');

    return TextButton(
      onPressed: () {
        if (onCallback != null) {
          onCallback(properties);
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: ParseUtils.parseColor(properties['foregroundColor']),
      ),
      child: child,
    );
  }

  /// Builds an IconButton widget
  /// 
  /// Properties:
  /// - icon: String (icon name, e.g., 'edit', 'delete')
  /// - size: double
  /// - color: String (hex color)
  /// - events: Map with 'onPressed' callback
  static Widget buildIconButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(Map<String, dynamic>)? onCallback,
  }) {
    return IconButton(
      icon: Icon(ParseUtils.parseIconData(properties['icon'] as String? ?? 'info')),
      iconSize: ParseUtils.parseDouble(properties['size']) ?? 24.0,
      color: ParseUtils.parseColor(properties['color']),
      onPressed: () {
        if (onCallback != null) {
          onCallback(properties);
        }
      },
    );
  }

  /// Builds an OutlinedButton widget
  /// 
  /// Properties:
  /// - label: String (button text)
  /// - foregroundColor: String (hex color)
  /// - borderColor: String (hex color)
  /// - events: Map with 'onPressed' callback
  static Widget buildOutlinedButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Widget Function(Map<String, dynamic>, {List<dynamic>? childrenData, BuildContext? context})? render,
    Function(Map<String, dynamic>)? onCallback,
  }) {
    final childrenData = properties['children'] as List? ?? [];
    final child = childrenData.isNotEmpty && render != null
        ? render(childrenData.first as Map<String, dynamic>, childrenData: null, context: context)
        : Text(properties['label'] as String? ?? 'Button');

    return OutlinedButton(
      onPressed: () {
        if (onCallback != null) {
          onCallback(properties);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: ParseUtils.parseColor(properties['foregroundColor']),
        side: BorderSide(
          color: ParseUtils.parseColor(properties['borderColor']) ?? Colors.black,
        ),
      ),
      child: child,
    );
  }

  // ===== TEXT INPUT WIDGETS =====

  /// Builds a TextField widget
  /// 
  /// Properties:
  /// - fieldId: String (unique field identifier)
  /// - label: String (label text)
  /// - hint: String (hint text)
  /// - obscureText: bool (for passwords)
  /// - maxLines: int
  /// - minLines: int
  /// - textInputType: String (text, number, email, phone, url, multiline)
  static Widget buildTextField(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Map<String, TextEditingController>? fieldControllers,
  }) {
    final fieldId = properties['fieldId'] as String? ?? 'field_${DateTime.now().millisecondsSinceEpoch}';
    
    // Get or create controller for this field
    final controller = fieldControllers != null
        ? (fieldControllers.putIfAbsent(
            fieldId,
            () => TextEditingController(),
          ))
        : TextEditingController();

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] as bool? ?? false,
      maxLines: properties['maxLines'] as int? ?? 1,
      minLines: properties['minLines'] as int?,
      keyboardType: _parseTextInputType(properties['textInputType']),
    );
  }

  /// Builds a TextFormField widget
  /// 
  /// Properties:
  /// - label: String (label text)
  /// - hint: String (hint text)
  /// - obscureText: bool (for passwords)
  /// - validator: String (optional validation message)
  /// - maxLines: int
  /// - minLines: int
  static Widget buildTextFormField(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: properties['label'] as String?,
        hintText: properties['hint'] as String?,
        border: const OutlineInputBorder(),
      ),
      obscureText: properties['obscureText'] as bool? ?? false,
      maxLines: properties['maxLines'] as int? ?? 1,
      minLines: properties['minLines'] as int?,
      validator: (value) {
        final validatorMsg = properties['validator'] as String?;
        if (validatorMsg != null && (value == null || value.isEmpty)) {
          return validatorMsg;
        }
        return null;
      },
    );
  }

  // ===== CHECKBOX WIDGETS =====

  /// Builds a Checkbox widget
  /// 
  /// Properties:
  /// - value: bool (checked state)
  /// - activeColor: String (hex color)
  /// - checkColor: String (hex color)
  static Widget buildCheckbox(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(bool)? onChanged,
  }) {
    return Checkbox(
      value: properties['value'] as bool? ?? false,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      checkColor: ParseUtils.parseColor(properties['checkColor']),
      onChanged: (bool? value) {
        if (onChanged != null && value != null) {
          onChanged(value);
        }
      },
    );
  }

  /// Builds a CheckboxListTile widget
  /// 
  /// Properties:
  /// - label: String (tile label)
  /// - value: bool (checked state)
  /// - activeColor: String (hex color)
  /// - subtitle: String (optional subtitle)
  static Widget buildCheckboxListTile(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(bool)? onChanged,
  }) {
    return CheckboxListTile(
      title: Text(properties['label'] as String? ?? ''),
      subtitle: properties['subtitle'] != null
          ? Text(properties['subtitle'] as String)
          : null,
      value: properties['value'] as bool? ?? false,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      onChanged: (bool? value) {
        if (onChanged != null && value != null) {
          onChanged(value);
        }
      },
    );
  }

  // ===== RADIO WIDGETS =====

  /// Builds a Radio widget
  /// 
  /// Properties:
  /// - value: String (radio value)
  /// - groupValue: String (current selected value)
  /// - activeColor: String (hex color)
  static Widget buildRadio(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String)? onChanged,
  }) {
    return Radio<String>(
      value: properties['value'] as String? ?? '',
      groupValue: properties['groupValue'] as String?,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      onChanged: (String? value) {
        if (onChanged != null && value != null) {
          onChanged(value);
        }
      },
    );
  }

  /// Builds a RadioListTile widget
  /// 
  /// Properties:
  /// - label: String (tile label)
  /// - value: String (radio value)
  /// - groupValue: String (current selected value)
  /// - activeColor: String (hex color)
  /// - subtitle: String (optional subtitle)
  static Widget buildRadioListTile(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String)? onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(properties['label'] as String? ?? ''),
      subtitle: properties['subtitle'] != null
          ? Text(properties['subtitle'] as String)
          : null,
      value: properties['value'] as String? ?? '',
      groupValue: properties['groupValue'] as String?,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      onChanged: (String? value) {
        if (onChanged != null && value != null) {
          onChanged(value);
        }
      },
    );
  }

  // ===== SWITCH WIDGETS =====

  /// Builds a Switch widget
  /// 
  /// Properties:
  /// - value: bool (switch state)
  /// - activeColor: String (hex color)
  /// - inactiveThumbColor: String (hex color)
  /// - inactiveTrackColor: String (hex color)
  static Widget buildSwitch(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(bool)? onChanged,
  }) {
    return Switch(
      value: properties['value'] as bool? ?? false,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      inactiveThumbColor: ParseUtils.parseColor(properties['inactiveThumbColor']),
      inactiveTrackColor: ParseUtils.parseColor(properties['inactiveTrackColor']),
      onChanged: (bool value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  /// Builds a SwitchListTile widget
  /// 
  /// Properties:
  /// - label: String (tile label)
  /// - value: bool (switch state)
  /// - activeColor: String (hex color)
  /// - subtitle: String (optional subtitle)
  static Widget buildSwitchListTile(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(bool)? onChanged,
  }) {
    return SwitchListTile(
      title: Text(properties['label'] as String? ?? ''),
      subtitle: properties['subtitle'] != null
          ? Text(properties['subtitle'] as String)
          : null,
      value: properties['value'] as bool? ?? false,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      onChanged: (bool value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  // ===== SLIDER WIDGETS =====

  /// Builds a Slider widget
  /// 
  /// Properties:
  /// - value: double (current value)
  /// - min: double (minimum value)
  /// - max: double (maximum value)
  /// - divisions: int (number of discrete divisions)
  /// - activeColor: String (hex color)
  /// - inactiveColor: String (hex color)
  static Widget buildSlider(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(double)? onChanged,
  }) {
    final value = ParseUtils.parseDouble(properties['value']) ?? 0.0;
    final min = ParseUtils.parseDouble(properties['min']) ?? 0.0;
    final max = ParseUtils.parseDouble(properties['max']) ?? 100.0;

    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: (properties['divisions'] as num?)?.toInt(),
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      inactiveColor: ParseUtils.parseColor(properties['inactiveColor']),
      onChanged: (double value) {
        if (onChanged != null) {
          onChanged(value);
        }
      },
    );
  }

  /// Builds a RangeSlider widget
  /// 
  /// Properties:
  /// - start: double (start value)
  /// - end: double (end value)
  /// - min: double (minimum value)
  /// - max: double (maximum value)
  /// - activeColor: String (hex color)
  /// - inactiveColor: String (hex color)
  static Widget buildRangeSlider(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(RangeValues)? onChanged,
  }) {
    final start = ParseUtils.parseDouble(properties['start']) ?? 0.0;
    final end = ParseUtils.parseDouble(properties['end']) ?? 50.0;
    final min = ParseUtils.parseDouble(properties['min']) ?? 0.0;
    final max = ParseUtils.parseDouble(properties['max']) ?? 100.0;

    return RangeSlider(
      values: RangeValues(start, end),
      min: min,
      max: max,
      activeColor: ParseUtils.parseColor(properties['activeColor']),
      inactiveColor: ParseUtils.parseColor(properties['inactiveColor']),
      onChanged: (RangeValues values) {
        if (onChanged != null) {
          onChanged(values);
        }
      },
    );
  }

  // ===== DROPDOWN & MENU WIDGETS =====

  /// Builds a DropdownButton widget
  /// 
  /// Properties:
  /// - items: List<String> (dropdown options)
  /// - value: String (currently selected value)
  /// - hint: String (hint text when no value selected)
  static Widget buildDropdownButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String?)? onChanged,
  }) {
    final items = properties['items'] as List? ?? [];
    final value = properties['value'] as String?;
    
    return DropdownButton<String>(
      value: value,
      hint: Text(properties['hint'] as String? ?? 'Select an option'),
      items: items
          .map((item) => DropdownMenuItem<String>(
                value: item.toString(),
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: (String? newValue) {
        if (onChanged != null) {
          onChanged(newValue);
        }
      },
    );
  }

  /// Builds a PopupMenuButton widget
  /// 
  /// Properties:
  /// - items: List<String> (menu options)
  /// - icon: String (icon name)
  static Widget buildPopupMenuButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(String)? onSelected,
  }) {
    final items = properties['items'] as List? ?? [];
    
    return PopupMenuButton<String>(
      icon: Icon(ParseUtils.parseIconData(properties['icon'] as String? ?? 'more_vert')),
      itemBuilder: (BuildContext context) => items
          .map((item) => PopupMenuItem<String>(
                value: item.toString(),
                child: Text(item.toString()),
              ))
          .toList(),
      onSelected: (String value) {
        if (onSelected != null) {
          onSelected(value);
        }
      },
    );
  }

  /// Builds a SegmentedButton widget
  /// 
  /// Properties:
  /// - segments: List<String> (button labels)
  /// - selected: String (currently selected segment)
  static Widget buildSegmentedButton(
    Map<String, dynamic> properties, {
    List<dynamic>? childrenData,
    BuildContext? context,
    Function(Set<String>)? onSelectionChanged,
  }) {
    final segments = properties['segments'] as List? ?? [];
    final selected = properties['selected'] as String?;
    
    return SegmentedButton<String>(
      segments: segments
          .map((seg) => ButtonSegment(
                label: Text(seg.toString()),
                value: seg.toString(),
              ))
          .toList(),
      selected: {selected ?? (segments.isNotEmpty ? segments.first.toString() : '')},
      onSelectionChanged: (Set<String> selection) {
        if (onSelectionChanged != null) {
          onSelectionChanged(selection);
        }
      },
    );
  }

  // ===== HELPER METHODS =====

  /// Parses text input type
  static TextInputType _parseTextInputType(dynamic value) {
    if (value == null) return TextInputType.text;
    
    final str = value.toString().toLowerCase().trim();
    switch (str) {
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      case 'text':
      default:
        return TextInputType.text;
    }
  }
}
