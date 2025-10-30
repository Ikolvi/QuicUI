# Offline Sync App Example

## Overview
An offline-first application demonstrating:
- **Offline Detection**: Monitor network connectivity
- **Local Storage**: Store data locally using ObjectBox
- **Sync Operations**: Synchronize local data with backend
- **Pending Changes**: Display sync status
- **Error Handling**: Handle offline scenarios gracefully
- **Cache Management**: Clear and manage local data

## Features
✅ Automatic offline detection  
✅ Local data persistence  
✅ Background sync capability  
✅ Pending changes queue  
✅ Last sync timestamp  
✅ Storage usage tracking  
✅ Cache management  

## JSON Structure

### Connectivity Status Display
```json
{
  "id": "container_sync_status",
  "type": "Container",
  "properties": {
    "backgroundColor": "{isOnline ? '#4CAF50' : '#F44336'}"
  },
  "stateBinding": {
    "variable": "isOnline",
    "defaultValue": true
  }
}
```

### Sync Information Cards
```json
{
  "id": "card_sync_info",
  "type": "Card",
  "children": [
    {
      "id": "text_pending_count",
      "type": "Text",
      "stateBinding": {
        "variable": "pendingSyncCount",
        "defaultValue": "0"
      }
    }
  ]
}
```

### Sync Actions
```json
"actions": [
  {
    "type": "syncOfflineData",
    "endpoint": "/api/sync",
    "method": "POST"
  }
]
```

## Key Concepts

### Offline-First Architecture
1. **Create**: Data saved to local database first
2. **Display**: Show data immediately from local storage
3. **Sync**: Background sync with server when online
4. **Resolve**: Handle conflicts if they occur

### State Variables
- **isOnline**: Network connectivity status
- **pendingSyncCount**: Number of items waiting to sync
- **lastSyncTime**: Timestamp of last successful sync
- **storageUsed**: Amount of local storage used

### Sync Operations
- **Automatic**: Sync when connection restored
- **Manual**: User-triggered sync via button
- **Incremental**: Only sync changes since last sync
- **Conflict Resolution**: Merge local and remote changes

### Local Storage Strategy
```
App Data
├── Synced Data (read-only from server)
├── Local Cache (writable, auto-synced)
└── Pending Queue (changes waiting to sync)
```

## Implementation Details

### Detection Strategy
- Monitor network connectivity
- Use connectivity_plus package
- Update UI based on status

### Local Database
- ObjectBox for high performance
- Automatic schema management
- Transaction support

### Sync Queue
- Queue changes when offline
- Store operation type (create, update, delete)
- Track sync attempts and retries

### Conflict Resolution
- Last write wins (default)
- Server version takes precedence
- Manual merge UI for complex conflicts

## Testing
This app is tested with:
- Online/offline state tests
- Sync operation tests
- Conflict resolution tests
- Cache management tests
- Error handling tests
- Storage usage tests

See `test/examples/offline_sync_app_test.dart` for implementation.

## Running the Example
```bash
flutter run --dart-define=QUICUI_CONFIG=offline_sync_app.json
```

## API Integration

### Sync Endpoint
**POST /api/sync**

Request:
```json
{
  "clientId": "device-id",
  "changes": [
    {
      "type": "create",
      "entity": "todo",
      "data": {...}
    },
    {
      "type": "update",
      "entity": "todo",
      "id": "123",
      "data": {...}
    },
    {
      "type": "delete",
      "entity": "todo",
      "id": "456"
    }
  ]
}
```

Response:
```json
{
  "success": true,
  "timestamp": "2024-01-01T10:30:00Z",
  "synced": 5,
  "failed": 0
}
```

## Advanced Features
- Incremental sync
- Bandwidth optimization
- Compression
- Selective sync (sync specific tables)
- Conflict resolution UI
- Sync history
- Retry logic with exponential backoff

## Next Steps
- Implement background sync service
- Add sync history viewer
- Create conflict resolution UI
- Implement selective sync
- Add data encryption
- Monitor sync metrics
