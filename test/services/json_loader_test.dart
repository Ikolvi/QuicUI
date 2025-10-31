import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/src/services/json_loader.dart';

// Tests for JSONLoader service with caching and JSON management
void main() {
  group('JSONLoader Tests', () {
    setUp(() {
      JSONLoader.clearCache();
    });

    test('cacheJson stores data', () {
      final testData = {'type': 'Screen', 'screens': {}};
      JSONLoader.cacheJson('test_flow', testData);
      
      final retrieved = JSONLoader.getCachedJson('test_flow');
      expect(retrieved, isNotNull);
      expect(retrieved!['type'], equals('Screen'));
    });

    test('getCachedJson returns null for non-existent key', () {
      JSONLoader.clearCache();
      final result = JSONLoader.getCachedJson('nonexistent');
      expect(result, isNull);
    });

    test('clearCache removes all entries', () {
      JSONLoader.cacheJson('key1', {'type': 'Flow'});
      JSONLoader.cacheJson('key2', {'type': 'Flow'});
      
      JSONLoader.clearCache();
      
      expect(JSONLoader.getCachedJson('key1'), isNull);
      expect(JSONLoader.getCachedJson('key2'), isNull);
    });

    test('clearCache with specific key', () {
      JSONLoader.cacheJson('key1', {'type': 'Flow'});
      JSONLoader.cacheJson('key2', {'type': 'Flow'});
      
      JSONLoader.clearCache(key: 'key1');
      
      expect(JSONLoader.getCachedJson('key1'), isNull);
      expect(JSONLoader.getCachedJson('key2'), isNotNull);
    });

    test('getCacheStats returns valid statistics', () {
      JSONLoader.cacheJson('flow1', {'type': 'Flow'});
      JSONLoader.cacheJson('flow2', {'type': 'Flow'});
      
      final stats = JSONLoader.getCacheStats();
      expect(stats['cachedFlows'], equals(2));
      expect(stats['cachedKeys'], isNotNull);
    });

    test('validateJsonStructure accepts valid JSON', () {
      final validJson = {'type': 'Screen', 'screens': {}};
      expect(() => JSONLoader.validateJsonStructure(validJson), returnsNormally);
    });

    test('validateJsonStructure rejects invalid JSON', () {
      final invalidJson = {'random': 'data'};
      expect(
        () => JSONLoader.validateJsonStructure(invalidJson),
        throwsFormatException,
      );
    });

    test('loadJsonFromFile throws UnimplementedError', () async {
      try {
        await JSONLoader.loadJsonFromFile('test.json');
        fail('Expected UnimplementedError');
      } catch (e) {
        expect(e, isA<UnimplementedError>());
      }
    });

    test('loadJsonFromUrl throws UnimplementedError', () async {
      try {
        await JSONLoader.loadJsonFromUrl('http://example.com/test.json');
        fail('Expected UnimplementedError');
      } catch (e) {
        expect(e, isA<UnimplementedError>());
      }
    });

    test('multiple JSON files cached independently', () {
      final authFlow = {'type': 'Flow', 'screens': {'login': {}}};
      final dashboardFlow = {'type': 'Flow', 'screens': {'home': {}}};
      
      JSONLoader.cacheJson('auth', authFlow);
      JSONLoader.cacheJson('dashboard', dashboardFlow);
      
      final auth = JSONLoader.getCachedJson('auth');
      final dashboard = JSONLoader.getCachedJson('dashboard');
      
      expect(auth!['screens'].keys.first, equals('login'));
      expect(dashboard!['screens'].keys.first, equals('home'));
    });

    test('cache returns copies not references', () {
      final original = {'data': {'nested': 'value'}};
      JSONLoader.cacheJson('original', original);
      
      final retrieved1 = JSONLoader.getCachedJson('original')!;
      retrieved1['data']['nested'] = 'modified';
      
      final retrieved2 = JSONLoader.getCachedJson('original')!;
      expect(retrieved2['data']['nested'], equals('value'));
    });
  });
}
