import 'package:quicui/quicui.dart';

void main() {
  // Test 1: WidgetData without id
  print('Test 1: Creating WidgetData without id...');
  try {
    final textWidget = WidgetData(
      type: 'text',
      properties: {'text': 'Hello, World!'},
    );
    print('✓ SUCCESS: WidgetData created without id');
    print('  Widget: $textWidget');
    print('  ID field value: ${textWidget.id}');
  } catch (e) {
    print('✗ ERROR: ${e.toString()}');
  }

  // Test 2: WidgetData with id
  print('\nTest 2: Creating WidgetData with id...');
  try {
    final textWidget = WidgetData(
      type: 'text',
      properties: {'text': 'Hello, World!'},
      id: 'greeting_text',
    );
    print('✓ SUCCESS: WidgetData created with id');
    print('  Widget: $textWidget');
    print('  ID field value: ${textWidget.id}');
  } catch (e) {
    print('✗ ERROR: ${e.toString()}');
  }

  // Test 3: fromJson without id
  print('\nTest 3: Creating WidgetData from JSON without id...');
  try {
    final json = {
      'type': 'text',
      'properties': {'text': 'Hello, World!'},
    };
    final textWidget = WidgetData.fromJson(json);
    print('✓ SUCCESS: WidgetData created from JSON without id');
    print('  Widget: $textWidget');
    print('  ID field value: ${textWidget.id}');
  } catch (e) {
    print('✗ ERROR: ${e.toString()}');
  }

  // Test 4: fromJson with id
  print('\nTest 4: Creating WidgetData from JSON with id...');
  try {
    final json = {
      'type': 'text',
      'properties': {'text': 'Hello, World!'},
      'id': 'greeting_text',
    };
    final textWidget = WidgetData.fromJson(json);
    print('✓ SUCCESS: WidgetData created from JSON with id');
    print('  Widget: $textWidget');
    print('  ID field value: ${textWidget.id}');
  } catch (e) {
    print('✗ ERROR: ${e.toString()}');
  }

  print('\n=== All tests completed ===');
}
