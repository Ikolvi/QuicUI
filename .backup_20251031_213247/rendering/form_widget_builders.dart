/// Form widget builders for QuicUI rendering
///
/// Provides builder methods for form-related Flutter widgets.
/// Integrates with FormBuilder and form system for JSON-based form creation.

import 'package:flutter/material.dart';
import '../forms/form_builder.dart';
import '../forms/form_controller.dart';
import '../utils/logger_util.dart';

/// Builder class for form-related widgets
class FormWidgetBuilders {
  /// Build a Form widget
  ///
  /// Properties:
  /// - formId: Unique form identifier
  /// - fields: List of FormFieldConfig objects
  /// - onSubmit: Submission callback (optional)
  /// - autovalidate: Auto validation mode
  static Widget buildForm(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final formId = properties['formId'] ?? 'default_form';
      final autovalidate = properties['autovalidate'] ?? false;
      
      // Create form configuration from properties
      final config = FormBuilderConfig(
        formId: formId,
        fields: [],
        // Additional properties can be set from the JSON
      );

      // Build the form controller
      final controller = FormBuilder.buildController(config);

      return FormWidget(
        controller: controller,
        autovalidate: autovalidate,
        properties: properties,
        render: render,
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building Form widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a TextFormField widget
  ///
  /// Properties:
  /// - fieldId: Form field identifier
  /// - label: Field label
  /// - hint: Placeholder text
  /// - initialValue: Initial field value
  /// - validator: Validation rules
  /// - required: Is field required
  /// - keyboardType: Keyboard type (text, email, phone, etc.)
  /// - obscureText: Hide input (for passwords)
  static Widget buildTextFormField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final hint = properties['hint'] ?? '';
      final initialValue = properties['initialValue'] ?? '';
      final required = properties['required'] ?? false;
      final obscureText = properties['obscureText'] ?? false;
      final maxLines = properties['maxLines'] ?? 1;
      final minLines = properties['minLines'];
      
      // Keyboard type mapping
      final keyboardTypeStr = properties['keyboardType'] ?? 'text';
      final keyboardType = _parseKeyboardType(keyboardTypeStr);

      return TextFormField(
        initialValue: initialValue.toString(),
        decoration: InputDecoration(
          labelText: label.isNotEmpty ? label : null,
          hintText: hint.isNotEmpty ? hint : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        minLines: minLines,
        validator: required
            ? (value) => (value == null || value.isEmpty ? 'This field is required' : null)
            : null,
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building TextFormField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a Checkbox widget
  ///
  /// Properties:
  /// - fieldId: Field identifier
  /// - label: Checkbox label
  /// - value: Current checkbox value
  /// - onChanged: Change callback (optional)
  static Widget buildCheckboxField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final value = properties['value'] ?? false;

      return CheckboxListTile(
        title: Text(label),
        value: value as bool,
        onChanged: (newValue) {
          // Update form state if needed
        },
        dense: true,
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building CheckboxField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a Radio button widget
  ///
  /// Properties:
  /// - fieldId: Field identifier
  /// - label: Radio label
  /// - value: Radio value
  /// - groupValue: Current group value
  /// - onChanged: Change callback (optional)
  static Widget buildRadioField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final value = properties['value'] ?? '';
      final groupValue = properties['groupValue'] ?? '';

      return RadioListTile(
        title: Text(label),
        value: value,
        groupValue: groupValue,
        onChanged: (newValue) {
          // Update form state if needed
        },
        dense: true,
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building RadioField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a DropdownButton field
  ///
  /// Properties:
  /// - fieldId: Field identifier
  /// - label: Field label
  /// - value: Current value
  /// - options: List of options
  /// - onChanged: Change callback (optional)
  static Widget buildSelectField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final value = properties['value'];
      final optionsList = properties['options'] as List? ?? [];

      return DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label.isNotEmpty ? label : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        value: value,
        items: optionsList
            .map<DropdownMenuItem<String>>((option) => DropdownMenuItem(
                  value: option['value']?.toString() ?? option.toString(),
                  child: Text(option['label']?.toString() ?? option.toString()),
                ))
            .toList(),
        onChanged: (newValue) {
          // Update form state if needed
        },
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building SelectField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a Slider field
  ///
  /// Properties:
  /// - fieldId: Field identifier
  /// - label: Field label
  /// - value: Current value
  /// - min: Minimum value
  /// - max: Maximum value
  /// - divisions: Number of divisions
  /// - onChanged: Change callback (optional)
  static Widget buildSliderField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final value = (properties['value'] ?? 0.0).toDouble();
      final min = (properties['min'] ?? 0.0).toDouble();
      final max = (properties['max'] ?? 100.0).toDouble();
      final divisions = properties['divisions'] as int?;

      return Column(
        children: [
          if (label.isNotEmpty) Text(label),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.toString(),
            onChanged: (newValue) {
              // Update form state if needed
            },
          ),
        ],
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building SliderField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a Switch field
  ///
  /// Properties:
  /// - fieldId: Field identifier
  /// - label: Field label
  /// - value: Current value
  /// - onChanged: Change callback (optional)
  static Widget buildSwitchField(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? '';
      final value = properties['value'] ?? false;

      return SwitchListTile(
        title: Text(label),
        value: value as bool,
        onChanged: (newValue) {
          // Update form state if needed
        },
        dense: true,
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building SwitchField widget', e, stackTrace);
      return const Placeholder();
    }
  }

  /// Build a FormSubmitButton widget
  ///
  /// Properties:
  /// - label: Button label
  /// - onSubmit: Submission callback
  /// - formId: Form identifier to submit
  static Widget buildFormSubmitButton(
    Map<String, dynamic> properties,
    List<dynamic> childrenData,
    BuildContext? context,
    dynamic render,
  ) {
    try {
      final label = properties['label'] ?? 'Submit';

      return ElevatedButton(
        onPressed: () {
          // Trigger form submission
          LoggerUtil.info('Form submit button pressed: $label');
        },
        child: Text(label),
      );
    } catch (e, stackTrace) {
      LoggerUtil.error('Error building FormSubmitButton widget', e, stackTrace);
      return const Placeholder();
    }
  }

  // ===== HELPER METHODS =====

  /// Parse keyboard type from string
  static TextInputType _parseKeyboardType(String typeStr) {
    return switch (typeStr.toLowerCase()) {
      'email' => TextInputType.emailAddress,
      'phone' => TextInputType.phone,
      'number' => TextInputType.number,
      'decimal' => const TextInputType.numberWithOptions(decimal: true),
      'url' => TextInputType.url,
      'multiline' => TextInputType.multiline,
      'datetime' => TextInputType.datetime,
      _ => TextInputType.text,
    };
  }
}

/// Internal Form widget wrapper
class FormWidget extends StatefulWidget {
  final FormController controller;
  final bool autovalidate;
  final Map<String, dynamic> properties;
  final dynamic render;

  const FormWidget({
    required this.controller,
    required this.autovalidate,
    required this.properties,
    required this.render,
  });

  @override
  State<FormWidget> createState() => _FormWidgetState();
}

class _FormWidgetState extends State<FormWidget> {
  @override
  void initState() {
    super.initState();
    // Add listener for form changes if needed
    widget.controller.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onFormChanged);
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      autovalidateMode: widget.autovalidate
          ? AutovalidateMode.always
          : AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          // Form will render its fields via the render function
          if (widget.properties['children'] != null)
            widget.render(widget.properties['children'] as List<dynamic>)
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
