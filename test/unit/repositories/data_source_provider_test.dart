import 'package:flutter_test/flutter_test.dart';
import 'package:quicui/quicui.dart';
import 'package:quicui/src/repositories/data_source_provider.dart';

// Mock DataSource implementation for testing
class MockDataSource implements DataSource {
  @override
  Future<Screen> fetchScreen(String screenId) async {
    return Screen(
      id: screenId,
      name: 'Mock Screen',
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
    return [
      Screen(
        id: 'screen1',
        name: 'Screen 1',
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
      ),
      Screen(
        id: 'screen2',
        name: 'Screen 2',
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
      ),
    ];
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
  Future<SyncResult> syncData(List<SyncItem> pendingItems) async {
    return SyncResult(
      synced: 0,
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
    return Stream.empty();
  }

  @override
  Future<void> unsubscribe(String screenId) async {}
}

void main() {
  // Reset state before each test
  setUp(() {
    DataSourceProvider.instance.unregister();
  });

  group('DataSourceProvider', () {
    group('register()', () {
      test('registers a DataSource successfully', () {
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);
        expect(DataSourceProvider.instance.isRegistered, isTrue);
      });

      test('allows replacing an existing DataSource', () {
        final dataSource1 = MockDataSource();
        final dataSource2 = MockDataSource();

        DataSourceProvider.instance.register(dataSource1);
        expect(DataSourceProvider.instance.isRegistered, isTrue);

        DataSourceProvider.instance.register(dataSource2);
        expect(DataSourceProvider.instance.isRegistered, isTrue);
      });

      test('stores the exact DataSource instance', () {
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);

        final retrieved = DataSourceProvider.instance.get();
        expect(identical(retrieved, dataSource), isTrue);
      });
    });

    group('get()', () {
      test('returns registered DataSource', () {
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);

        final retrieved = DataSourceProvider.instance.get();
        expect(retrieved, isA<DataSource>());
      });

      test('throws DataSourceProviderException if not registered', () {
        expect(
          () => DataSourceProvider.instance.get(),
          throwsA(isA<DataSourceProviderException>()),
        );
      });

      test('exception contains helpful error message', () {
        try {
          DataSourceProvider.instance.get();
          fail('Should have thrown');
        } on DataSourceProviderException catch (e) {
          expect(
            e.message.contains('DataSource not registered'),
            isTrue,
          );
          expect(
            e.message.contains('DataSourceProvider.instance.register()'),
            isTrue,
          );
        }
      });
    });

    group('isRegistered', () {
      test('returns false when no DataSource is registered', () {
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });

      test('returns true when DataSource is registered', () {
        DataSourceProvider.instance.register(MockDataSource());
        expect(DataSourceProvider.instance.isRegistered, isTrue);
      });

      test('returns false after unregister', () {
        DataSourceProvider.instance.register(MockDataSource());
        expect(DataSourceProvider.instance.isRegistered, isTrue);

        DataSourceProvider.instance.unregister();
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });
    });

    group('unregister()', () {
      test('removes registered DataSource', () {
        DataSourceProvider.instance.register(MockDataSource());
        expect(DataSourceProvider.instance.isRegistered, isTrue);

        DataSourceProvider.instance.unregister();
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });

      test('is safe to call when nothing registered', () {
        expect(DataSourceProvider.instance.isRegistered, isFalse);

        // Should not throw
        DataSourceProvider.instance.unregister();
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });

      test('prevents access to unregistered DataSource', () {
        DataSourceProvider.instance.register(MockDataSource());
        DataSourceProvider.instance.unregister();

        expect(
          () => DataSourceProvider.instance.get(),
          throwsA(isA<DataSourceProviderException>()),
        );
      });
    });

    group('getOrNull()', () {
      test('returns registered DataSource', () {
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);

        final retrieved = DataSourceProvider.instance.getOrNull();
        expect(identical(retrieved, dataSource), isTrue);
      });

      test('returns null when not registered', () {
        expect(DataSourceProvider.instance.getOrNull(), isNull);
      });

      test('does not throw when not registered', () {
        expect(
          () => DataSourceProvider.instance.getOrNull(),
          returnsNormally,
        );
      });

      test('allows safe conditional access', () {
        final dataSource = DataSourceProvider.instance.getOrNull();
        if (dataSource != null) {
          fail('Should be null');
        }

        DataSourceProvider.instance.register(MockDataSource());
        final retrieved = DataSourceProvider.instance.getOrNull();
        expect(retrieved, isNotNull);
      });
    });

    group('singleton pattern', () {
      test('always returns same instance', () {
        final instance1 = DataSourceProvider.instance;
        final instance2 = DataSourceProvider.instance;

        expect(identical(instance1, instance2), isTrue);
      });

      test('DataSource persists across instance accesses', () {
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);

        final retrieved1 = DataSourceProvider.instance.get();
        final retrieved2 = DataSourceProvider.instance.get();

        expect(identical(retrieved1, retrieved2), isTrue);
        expect(identical(retrieved1, dataSource), isTrue);
      });
    });

    group('integration scenarios', () {
      test('complete workflow: register, use, unregister', () {
        // Initially not registered
        expect(DataSourceProvider.instance.isRegistered, isFalse);
        expect(DataSourceProvider.instance.getOrNull(), isNull);

        // Register
        final dataSource = MockDataSource();
        DataSourceProvider.instance.register(dataSource);
        expect(DataSourceProvider.instance.isRegistered, isTrue);

        // Use
        final retrieved = DataSourceProvider.instance.get();
        expect(retrieved, isA<DataSource>());

        // Unregister
        DataSourceProvider.instance.unregister();
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });

      test('handles multiple DataSources in sequence', () {
        final ds1 = MockDataSource();
        final ds2 = MockDataSource();

        // First DataSource
        DataSourceProvider.instance.register(ds1);
        expect(identical(DataSourceProvider.instance.get(), ds1), isTrue);

        // Replace with second
        DataSourceProvider.instance.register(ds2);
        expect(identical(DataSourceProvider.instance.get(), ds2), isTrue);

        // Clear
        DataSourceProvider.instance.unregister();
        expect(DataSourceProvider.instance.isRegistered, isFalse);
      });

      test('different DataSource types can be registered', () {
        // Even though we're using MockDataSource, in real app
        // this would test different implementations
        final mock = MockDataSource();
        DataSourceProvider.instance.register(mock);

        final retrieved = DataSourceProvider.instance.get();
        expect(retrieved.runtimeType.toString(), contains('MockDataSource'));
      });
    });
  });
}
