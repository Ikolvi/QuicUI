# Quick Reference: Supabase Package Separation

**Version:** 2.0.0 (Planned)  
**Type:** Quick Lookup Guide  
**Created:** October 30, 2025  

---

## 📚 Documentation Map

| Document | Lines | Purpose |
|----------|-------|---------|
| **SUPABASE_SEPARATION_PLAN.md** | 3,500+ | Complete implementation roadmap with 6 phases |
| **PLUGIN_ARCHITECTURE.md** | 2,500+ | Technical architecture & plugin system design |
| **CUSTOM_BACKEND_TEMPLATE.md** | 1,800+ | Step-by-step guide for implementing custom backends |
| **SEPARATION_PLANNING_SUMMARY.md** | 300+ | Overview of planning phase |
| **This Document** | 200+ | Quick reference guide |

---

## 🎯 At a Glance

### Problem
QuicUI is tightly coupled with Supabase. Can't use other backends.

### Solution
Separate into core + plugin architecture using abstract interfaces.

### Timeline
~4 weeks for v2.0.0 release

### Result
- ✅ QuicUI works with Supabase, Firebase, custom backends
- ✅ Cleaner core code
- ✅ Plugin ecosystem enabled

---

## 🏗️ Architecture (Before → After)

```
BEFORE (v1.1.0):
  QuicUI → Supabase (ONLY OPTION)

AFTER (v2.0.0):
  QuicUI → DataSource Interface → {Supabase | Firebase | Custom}
```

---

## 📦 New Packages

### Core: `quicui`
- **Remove:** supabase_flutter dependency
- **Add:** DataSource & RealtimeSource interfaces
- **Result:** ~15KB smaller, database-agnostic

### Plugin: `quicui_supabase` (NEW)
- **Dependency:** quicui + supabase_flutter
- **Provides:** SupabaseDataSource implementation
- **Install:** Existing Supabase users add this plugin

### Future: `quicui_firebase`, `quicui_amplify`, etc.

---

## 🔌 Interface Contract (Quick)

### DataSource (15 methods)

**Screen Operations:**
```dart
fetchScreen(String screenId)
fetchScreens({int limit, int offset})
saveScreen(String screenId, Screen screen)
deleteScreen(String screenId)
```

**Search & Query:**
```dart
searchScreens(String query)
getScreenCount()
```

**Sync:**
```dart
syncData(List<SyncItem> pendingItems)
getPendingItems()
resolveConflict(ConflictCase conflict)
```

**Connection:**
```dart
connect()
disconnect()
isConnected()
```

**Realtime:**
```dart
subscribeToScreen(String screenId)
unsubscribe(String screenId)
```

### RealtimeSource
```dart
onScreenChanged(String screenId)
onScreenCreated()
onScreenDeleted()
allEvents()
```

---

## 📊 6-Phase Implementation

| Phase | Duration | Focus |
|-------|----------|-------|
| 1 | 3-4 days | Define DataSource & RealtimeSource interfaces |
| 2 | 4-5 days | Refactor repositories to use interfaces |
| 3 | 2-3 days | Create DataSourceProvider service locator |
| 4 | 5-7 days | Build quicui_supabase plugin package |
| 5 | 2-3 days | Update QuicUIService initialization |
| 6 | 3-4 days | Update docs, examples, migration guide |
| **Total** | **~4 weeks** | **v2.0.0 Release** |

---

## 💻 Code Examples

### Using Supabase (v2.0.0)

```dart
import 'package:quicui_supabase/quicui_supabase.dart';

void main() async {
  await QuicUISupabase.initialize(
    url: 'https://xxx.supabase.co',
    anonKey: 'xxx',
  );
  runApp(const MyApp());
}
```

### Using Custom Backend (v2.0.0)

```dart
import 'package:quicui/quicui.dart';

class MyBackendDataSource implements DataSource {
  // Implement 15 interface methods
}

void main() async {
  DataSourceProvider.register(MyBackendDataSource());
  await QuicUI.initialize();
  runApp(const MyApp());
}
```

---

## ✅ Migration Path

### For Supabase Users (v1.1.0 → v2.0.0)

**Before:**
```dart
import 'package:quicui/quicui.dart';

await QuicUI.initialize(
  supabaseUrl: 'https://xxx.supabase.co',
  supabaseAnonKey: 'xxx',
);
```

**After (Option 1 - Use Supabase plugin):**
```dart
import 'package:quicui_supabase/quicui_supabase.dart';

await QuicUISupabase.initialize(
  url: 'https://xxx.supabase.co',
  anonKey: 'xxx',
);
```

**After (Option 2 - Generic interface):**
```dart
import 'package:quicui/quicui.dart';
import 'package:quicui_supabase/quicui_supabase.dart';

final dataSource = SupabaseDataSource(supabaseClient);
DataSourceProvider.register(dataSource);
await QuicUI.initialize();
```

---

## 📋 Files to Modify/Create

### Create (NEW)
- [ ] `lib/src/repositories/data_source_interface.dart`
- [ ] `lib/src/repositories/realtime_source_interface.dart`
- [ ] `lib/src/services/data_source_provider.dart`
- [ ] `quicui_supabase/` (entire package)
- [ ] `examples/custom_backend_template/`
- [ ] `docs/ARCHITECTURE_V2.md`
- [ ] `docs/MIGRATION_GUIDE.md`

### Modify
- [ ] `lib/src/repositories/screen_repository.dart`
- [ ] `lib/src/repositories/sync_repository.dart`
- [ ] `lib/src/services/quicui_service.dart`
- [ ] `pubspec.yaml` (remove supabase_flutter)
- [ ] `README.md`

### Move to Plugin
- [ ] `lib/src/services/supabase_service.dart`

---

## 🎯 Success Criteria

- [ ] QuicUI has zero Supabase dependencies
- [ ] DataSource interface fully implemented
- [ ] quicui_supabase plugin works standalone
- [ ] All 228 tests passing
- [ ] 85%+ test coverage
- [ ] Examples show database abstraction
- [ ] Documentation complete
- [ ] Migration guide provided
- [ ] Backward compatibility maintained

---

## 🔍 Key Files (Reference)

| File | Size | Purpose |
|------|------|---------|
| supabase_service.dart | 779 lines | **TO MOVE:** Supabase CRUD + auth |
| screen_repository.dart | ? | **TO REFACTOR:** Use DataSource |
| sync_repository.dart | ? | **TO REFACTOR:** Use DataSource |
| quicui_service.dart | ? | **TO UPDATE:** Generic initialization |
| pubspec.yaml | ? | **TO UPDATE:** Remove supabase_flutter |

---

## 🚀 Launch Checklist

### Pre-Implementation
- [x] All planning documents complete
- [x] Architecture decisions finalized
- [x] Interface contracts defined
- [x] Timeline established
- [x] Success criteria defined

### During Implementation
- [ ] Phase 1: Interfaces complete
- [ ] Phase 2: Repositories refactored
- [ ] Phase 3: DataSourceProvider working
- [ ] Phase 4: quicui_supabase plugin ready
- [ ] Phase 5: QuicUIService updated
- [ ] Phase 6: Docs & examples complete

### Pre-Release
- [ ] All 228 tests passing
- [ ] 85%+ coverage maintained
- [ ] 0 CVEs detected
- [ ] Performance tested
- [ ] Examples verified
- [ ] Migration guide reviewed

---

## 📞 Quick Links

**When You Need:**

| Need | Document | Section |
|------|----------|---------|
| Full implementation plan | SUPABASE_SEPARATION_PLAN.md | Any phase |
| Architecture details | PLUGIN_ARCHITECTURE.md | Architecture Layers |
| Code examples | PLUGIN_ARCHITECTURE.md | Plugin Implementation Guide |
| Custom backend setup | CUSTOM_BACKEND_TEMPLATE.md | Step-by-Step Implementation |
| Interface contracts | PLUGIN_ARCHITECTURE.md | Plugin Contract |
| Testing guide | CUSTOM_BACKEND_TEMPLATE.md | Testing Your Implementation |
| Error handling | CUSTOM_BACKEND_TEMPLATE.md | Advanced Patterns |

---

## 📊 Versioning

| Version | Status | Features |
|---------|--------|----------|
| v1.1.0 | ✅ Current | Supabase-only, Real-time, All TODOs done |
| v2.0.0-beta | 🔄 In Planning | Core separation, DataSource interface |
| v2.0.0-rc | ⏳ Future | Full separation, quicui_supabase |
| v2.0.0 | ⏳ Goal | Stable, plugin architecture, 3-4 weeks |
| v2.1.0+ | 💡 Vision | Additional plugins (Firebase, etc.) |

---

## 🎓 Learning Resources

1. **Start Here:** This document (5 min read)
2. **Architecture:** PLUGIN_ARCHITECTURE.md (30 min)
3. **Implementation:** SUPABASE_SEPARATION_PLAN.md (1 hour)
4. **Code:** CUSTOM_BACKEND_TEMPLATE.md (45 min)
5. **Do It:** Begin Phase 1 implementation

---

## ❓ FAQs

**Q: Will this break existing Supabase code?**  
A: No. v2.0.0 includes migration helpers and deprecation path.

**Q: When can we use Firebase instead of Supabase?**  
A: After v2.0.0 release. quicui_firebase planned for v2.1.0.

**Q: Can I implement my own backend?**  
A: Yes! Implement DataSource interface. See CUSTOM_BACKEND_TEMPLATE.md

**Q: How long will implementation take?**  
A: ~4 weeks (6 phases, 3-7 days each)

**Q: What's the size impact?**  
A: Core ~15KB smaller (no Supabase). Plugin adds ~50KB.

**Q: Do I need to use a plugin?**  
A: For Supabase: Yes (add quicui_supabase). For custom: Implement DataSource.

---

**Last Updated:** October 30, 2025  
**Status:** ✅ Ready for Implementation  
**Next Step:** Begin Phase 1 - Define Interfaces  

