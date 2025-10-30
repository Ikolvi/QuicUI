## 1.0.1 - October 30, 2025

### 🔄 Documentation & Supabase-Only Release

**Cloud Backend Updates**
- ✅ Removed all non-Supabase API key requirements
- ✅ Simplified to Supabase-only cloud integration
- ✅ Updated all documentation to reflect Supabase exclusive integration
- ✅ Cleaner initialization with only Supabase credentials required
- ✅ No hardcoded API keys or credentials

**Documentation Updates**
- Updated QuicUIService to show Supabase-only initialization
- Updated example app with Supabase setup
- Updated README with cloud-powered features
- Added Buy Me a Coffee support link
- Enhanced Supabase integration documentation

**What's Same**
- All 70+ widgets fully functional
- 228/228 tests passing
- Full offline-first support
- Real-time sync capability
- BLoC state management complete

**Breaking Changes**
- `initialize()` method now only requires `supabaseUrl` and `supabaseAnonKey`
- `appApiKey` parameter removed - no longer needed

### See Also
- [SUPABASE_INTEGRATION_GUIDE.md](SUPABASE_INTEGRATION_GUIDE.md) - Cloud integration guide
- [README.md](README.md) - Updated setup instructions

---

## 1.0.0 - October 30, 2025

### 🎉 Production Release

**Major Features**
- ✅ Complete QuicUI framework with offline-first architecture
- ✅ 70+ pre-built widgets with JSON configuration support
- ✅ BLoC state management with complete test coverage (228 tests)
- ✅ Supabase backend integration with real-time sync
- ✅ ObjectBox local persistence for offline-first apps
- ✅ Comprehensive Dartdoc for all public APIs (~11,000+ lines)

**Testing**
- 86 unit tests for widgets and rendering engine
- 38 integration tests for complex scenarios
- 5 production-grade example applications (Counter, Form, Todo, Offline Sync, Dashboard)
- 100% test pass rate (228/228)
- ~85% code coverage

**Performance**
- Optimized rendering engine
- Reduced memory footprint (~15% optimization)
- Build size optimization (~20% reduction)
- Maintained 60fps frame rate

**Documentation**
- Full Dartdoc for 20+ files covering all public APIs
- Service documentation with examples
- Widget documentation with usage patterns
- Best practices and architecture guides

### See Also
- [README.md](README.md) - Setup and usage instructions
- [PHASE_7_PLAN.md](PHASE_7_PLAN.md) - Performance optimization details

---

## 0.0.1

* Initial development version.
