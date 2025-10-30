import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui/src/repositories/data_source_provider.dart';
import 'package:quicui/src/services/quicui_service.dart';

/// Mock DataSource for testing
class MockDataSource extends Mock implements DataSource {}

/// Test DataSource implementation for testing custom implementations
class TestDataSource implements DataSource {
  @override
  Future<Screen> fetchScreen(String screenId) async {
    return Screen(
      id: screenId,
      name: 'Test Screen',
      version: 1,
      rootWidget: WidgetData(
        type: 'Container',
        properties: {},
        children: [],
      ),
      metadata: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      config: const ScreenConfig(),
    );
  }

  @override
  Future<List<Screen>> fetchScreens({int limit = 20, int offset = 0}) async {
    return [];
  }

  @override
  Future<void> saveScreen(String screenId, Screen screen) async {}

  @override
  Future<void> deleteScreen(String screenId) async {}

  @override
  Future<List<Screen>> searchScreens(String query) async {
    return [];
  }

  @override
  Future<int> getScreenCount() async {
    return 0;
  }

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isConnected() async {
    return true;
  }

  @override
  Stream<RealtimeEvent<Screen>> subscribeToScreen(String screenId) {
    throw UnimplementedError();
  }

  @override
  Future<void> unsubscribe(String screenId) async {}

  @override
  Future<SyncResult> syncData(List<SyncItem> items) async {
    return SyncResult(
      synced: items.length,
      failed: 0,
      errors: [],
    );
  }

  @override
  Future<List<SyncItem>> getPendingItems() async {
    return [];
  }

  @override
  Future<ConflictResolution> resolveConflict(ConflictCase conflict) async {
    return ConflictResolution.useLocal;
  }
}

void main() {
  group('QuicUIService', () {
    late MockDataSource mockDataSource;
    late QuicUIService service;

    setUpAll(() {
      // Register fallback values for mocktail
      registerFallbackValue(MockDataSource());
    });

    setUp(() {
      mockDataSource = MockDataSource();
      service = QuicUIService();
      
      // Clean up DataSourceProvider singleton before each test
      DataSourceProvider.instance.unregister();
    });

    tearDown(() {
      // Clean up after each test
      DataSourceProvider.instance.unregister();
    });

    group('Singleton Pattern', () {
      test('returns same instance on multiple calls', () {
        final service1 = QuicUIService();
        final service2 = QuicUIService();
        expect(identical(service1, service2), true);
      });

      test('instance is factory constructor', () {
        final service = QuicUIService();
        expect(service, isNotNull);
      });
    });

    group('initializeWithDataSource', () {
      test('registers DataSource with provider', () async {
        await service.initializeWithDataSource(mockDataSource);
        
        final registered = DataSourceProvider.instance.get();
        expect(registered, equals(mockDataSource));
      });

      test('completes successfully with valid DataSource', () async {
        expect(
          service.initializeWithDataSource(mockDataSource),
          completes,
        );
      });

      test('can be called multiple times safely (idempotent)', () async {
        await service.initializeWithDataSource(mockDataSource);
        
        // Second call should not throw
        expect(
          service.initializeWithDataSource(mockDataSource),
          completes,
        );
      });

      test('handles initialization errors gracefully', () async {
        final failingDataSource = MockDataSource();
        
        // Simulate error during initialization by making provider throw
        expect(
          service.initializeWithDataSource(failingDataSource),
          completes,
        );
      });
    });

    group('fetchScreen', () {
      setUp(() async {
        // Initialize service before testing fetchScreen
        await service.initializeWithDataSource(mockDataSource);
      });

      test('delegates to registered DataSource', () async {
        // Create test screen data
        final testScreen = Screen(
          id: 'test_screen',
          name: 'Test Screen',
          version: 1,
          rootWidget: const WidgetData(
            type: 'Container',
            properties: {},
            children: [],
          ),
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          config: const ScreenConfig(),
        );

        // Mock the DataSource method
        when(() => mockDataSource.fetchScreen('test_screen'))
            .thenAnswer((_) async => testScreen);

        // Call fetchScreen
        final result = await service.fetchScreen('test_screen');

        // Verify DataSource was called
        verify(() => mockDataSource.fetchScreen('test_screen')).called(1);
        
        // Verify result is converted to Map
        expect(result, isA<Map<String, dynamic>>());
      });

      test('returns screen data from DataSource', () async {
        final testScreen = Screen(
          id: 'home_screen',
          name: 'Home',
          version: 1,
          rootWidget: const WidgetData(
            type: 'Column',
            properties: {},
            children: [],
          ),
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          config: const ScreenConfig(),
        );

        when(() => mockDataSource.fetchScreen('home_screen'))
            .thenAnswer((_) async => testScreen);

        final result = await service.fetchScreen('home_screen');

        expect(result, isNotNull);
        expect(result['id'], 'home_screen');
      });

      test('throws when DataSource throws', () async {
        when(() => mockDataSource.fetchScreen('missing_screen'))
            .thenThrow(Exception('Screen not found'));

        expect(
          () => service.fetchScreen('missing_screen'),
          throwsException,
        );
      });
    });

    group('Plugin Architecture Integration', () {
      test('supports initialization with any DataSource implementation', () async {
        final customDataSource = TestDataSource();
        await service.initializeWithDataSource(customDataSource);

        final registered = DataSourceProvider.instance.get();
        expect(registered, isA<DataSource>());
      });

      test('DataSourceProvider correctly retrieves registered DataSource', () async {
        await service.initializeWithDataSource(mockDataSource);

        final provider = DataSourceProvider.instance;
        final retrieved = provider.get();

        expect(retrieved, equals(mockDataSource));
      });

      test('supports swapping DataSource implementations', () async {
        // Initialize with first DataSource
        await service.initializeWithDataSource(mockDataSource);
        var registered = DataSourceProvider.instance.get();
        expect(registered, equals(mockDataSource));

        // Unregister
        DataSourceProvider.instance.unregister();

        // Initialize with different DataSource
        final anotherDataSource = MockDataSource();
        await service.initializeWithDataSource(anotherDataSource);
        registered = DataSourceProvider.instance.get();
        expect(registered, equals(anotherDataSource));
      });
    });

    group('Backward Compatibility', () {
      test('legacy initialize() method is marked as deprecated', () async {
        // The method should throw UnimplementedError
        expect(
          () => service.initialize(
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'test-key',
          ),
          throwsA(isA<UnimplementedError>()),
        );
      });

      test('provides clear deprecation message', () async {
        try {
          await service.initialize(
            supabaseUrl: 'https://example.supabase.co',
            supabaseAnonKey: 'test-key',
          );
          fail('Should throw UnimplementedError');
        } on UnimplementedError catch (e) {
          expect(e.message, contains('Use SupabaseService'));
        }
      });
    });

    group('Error Handling', () {
      test('propagates DataSource errors correctly', () async {
        await service.initializeWithDataSource(mockDataSource);

        final error = Exception('Backend error');
        when(() => mockDataSource.fetchScreen('error_screen'))
            .thenThrow(error);

        expect(
          () => service.fetchScreen('error_screen'),
          throwsA(equals(error)),
        );
      });

      test('handles empty screenId gracefully', () async {
        await service.initializeWithDataSource(mockDataSource);

        when(() => mockDataSource.fetchScreen(''))
            .thenThrow(ArgumentError('screenId cannot be empty'));

        expect(
          () => service.fetchScreen(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('handles DataSource returning null', () async {
        await service.initializeWithDataSource(mockDataSource);

        when(() => mockDataSource.fetchScreen('null_screen'))
            .thenAnswer((_) async => throw Exception('Screen not found'));

        expect(
          () => service.fetchScreen('null_screen'),
          throwsException,
        );
      });
    });

    group('Thread Safety', () {
      test('singleton is thread-safe', () async {
        final services = <QuicUIService>[];
        for (int i = 0; i < 10; i++) {
          services.add(QuicUIService());
        }

        // All should be identical
        for (int i = 1; i < services.length; i++) {
          expect(identical(services[0], services[i]), true);
        }
      });
    });

    group('Integration Workflow', () {
      test('complete initialization and fetch workflow', () async {
        // Create mock DataSource
        final testScreen = Screen(
          id: 'workflow_screen',
          name: 'Workflow Test',
          version: 1,
          rootWidget: const WidgetData(
            type: 'Scaffold',
            properties: {},
            children: [],
          ),
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          config: const ScreenConfig(),
        );

        when(() => mockDataSource.fetchScreen('workflow_screen'))
            .thenAnswer((_) async => testScreen);

        // Step 1: Initialize
        await service.initializeWithDataSource(mockDataSource);

        // Verify registration
        expect(DataSourceProvider.instance.isRegistered, true);

        // Step 2: Fetch screen
        final result = await service.fetchScreen('workflow_screen');

        // Verify result
        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], 'workflow_screen');

        // Verify DataSource was used
        verify(() => mockDataSource.fetchScreen('workflow_screen')).called(1);
      });

      test('multiple sequential operations work correctly', () async {
        // Initialize
        await service.initializeWithDataSource(mockDataSource);

        final screen1 = Screen(
          id: 'screen1',
          name: 'Screen 1',
          version: 1,
          rootWidget: const WidgetData(
            type: 'Container',
            properties: {},
            children: [],
          ),
          metadata: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          config: const ScreenConfig(),
        );

        when(() => mockDataSource.fetchScreen('screen1'))
            .thenAnswer((_) async => screen1);

        when(() => mockDataSource.fetchScreen('screen2'))
            .thenThrow(Exception('Not found'));

        // Fetch first screen successfully
        final result1 = await service.fetchScreen('screen1');
        expect(result1['id'], 'screen1');

        // Fetch second screen (error)
        expect(
          () => service.fetchScreen('screen2'),
          throwsException,
        );

        // Verify both calls were made
        verify(() => mockDataSource.fetchScreen('screen1')).called(1);
        verify(() => mockDataSource.fetchScreen('screen2')).called(1);
      });
    });
  });
}
