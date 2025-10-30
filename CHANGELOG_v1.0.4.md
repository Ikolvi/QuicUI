# Changelog

## 1.0.4 - November 1, 2025

### 🔄 Generic Callback Action System

**New Features**
- ✅ Complete callback action system for interactive JSON-driven flows
- ✅ 4 generic action types: navigate, setState, apiCall, custom
- ✅ Action chaining with onSuccess and onError callbacks
- ✅ Support for all events: onPressed, onTap, onLongTap, onChanged, onSubmitted
- ✅ Full JSON serialization/deserialization with round-trip integrity
- ✅ Variable binding for form inputs, sliders, and app state
- ✅ Error recovery and conditional logic via custom handlers

**Core Implementation**
- `CallbackContext` class for action execution environment (138 lines)
- `Action` abstract base with factory pattern (660+ lines of 4 implementations)
- Complete type system: NavigateAction, SetStateAction, ApiCallAction, CustomAction
- All actions support nested callbacks for complex workflows
- Full support for arguments, body, query parameters, and headers

**Examples & Documentation**
- 3 comprehensive JSON example files demonstrating real-world flows
- CALLBACK_GUIDE.md: 600+ line complete reference guide
- CALLBACK_QUICK_START.md: Quick reference with patterns
- CALLBACK_ACTIONS_QUICK_REFERENCE.md: Updated for new system
- CALLBACK_SYSTEM_GENERIC_PLAN.md: Architecture and design decisions
- 5 common patterns: login flow, form validation, data refresh, toggles, deletion

**Testing**
- 29 comprehensive unit tests covering all action types
- JSON parsing and serialization round-trip tests
- Action chaining with nested callbacks
- Real-world scenario tests (login, validation, multi-step flows)
- Edge case handling and error recovery
- All tests passing (29/29)

**UIRenderer Integration**
- Updated _handleButtonPress for callback action support
- Backward compatible with existing string-based actions
- Proper error handling and null safety
- Clean separation using import aliases

**Quality**
- All 296/296 tests passing (29 new + 267 existing)
- No breaking changes
- Fully backward compatible
- Comprehensive error handling
- Full Dartdoc for new classes and methods

---

## 1.0.3 - October 30, 2025

### 📚 Plugin Documentation & Integration

**New Features**
- ✅ Added official plugins documentation section to README
- ✅ Added comprehensive QuicUI Supabase plugin reference
- ✅ Links to pub.dev packages for easy discovery
- ✅ Plugin installation and usage examples
- ✅ Cross-links between quicui and quicui_supabase packages

**Documentation**
- Added "🔌 Official Plugins" section with QuicUI Supabase integration
- Improved plugin discovery and setup instructions
- Added links to Supabase plugin on pub.dev
- Enhanced README with plugin ecosystem information

**Integration**
- All 267/267 tests passing
- Backward compatible with existing code
- Fully offline-first support maintained
- Optional cloud backend integration

---

## 1.0.2 - October 30, 2025

### 🎯 Backend-Optional & Examples Update

**Architecture Improvements**
- ✅ Backend is now completely optional - QuicUI works standalone with local JSON
- ✅ Clarified that `initializeWithDataSource()` is optional for cloud features only
- ✅ Framework can render JSON directly without any backend initialization
- ✅ Updated all documentation to reflect optional backend integration
- ✅ Plugin-based architecture remains flexible for any backend

**New Examples**
- ✅ Added Scaffold Counter App example (`examples/scaffold_counter_app.dart`)
- ✅ Demonstrates Material Design with Scaffold, AppBar, FloatingActionButton
- ✅ Shows state management and JSON-based UI rendering
- ✅ Counter JSON schema added to README with complete example

**Documentation Updates**
- Updated README with clear "backend is optional" messaging
- Added Minimal Setup (No Backend) section to Quick Start
- Added "Counter App with Scaffold" JSON schema example
- Updated examples README with Scaffold Counter App documentation
- Enhanced "Love QuicUI?" support section with catchy messaging
- Clarified QuicUI works perfectly offline and standalone

**Quality**
- All 267/267 tests passing
- No breaking changes
- Backward compatible with existing code
- Full offline-first support maintained

---

## 1.0.1 - October 30, 2025

### 📱 Documentation & Supabase-Only Release

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
- 5 production-grade example applications
- 100% test pass rate (228/228)
- ~85% code coverage

**Documentation**
- Full Dartdoc for all public APIs
- Service documentation with examples
- Widget documentation with usage patterns
- Best practices and architecture guides

---

## 0.0.1

* Initial development version.
