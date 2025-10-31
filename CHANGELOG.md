## 1.0.5 - October 31, 2025

### 🎨 Enhanced Padding/Margin & Task Manager Example

**New Padding/Margin Syntax** ✨
- ✅ **Enhanced `_parseEdgeInsets` support**: `{"all": 16}`, `{"horizontal": 20, "vertical": 10}` syntax
- ✅ **Backward Compatible**: All existing `{"left": x, "right": y}` syntax still works
- ✅ **75% Less JSON**: Common padding patterns now require much less code
- ✅ **Semantic Properties**: Clear intent with `all`, `horizontal`, `vertical` keywords
- ✅ **Mixed Format Support**: Combine different formats as needed

**Production-Ready Task Manager Example** 📱
- ✅ **Complete Flutter App**: Full-featured task management application
- ✅ **Advanced Layout Patterns**: Nested containers with proper spacing hierarchy
- ✅ **Mobile-Optimized Design**: Perfect touch targets and visual spacing
- ✅ **Overflow Prevention**: Proper `Expanded` widget usage for responsive text
- ✅ **Professional UI**: Material Design with shadows, borders, and gradients
- ✅ **Real-World JSON**: Complex, production-ready UI structure example

**Flutter API Modernization** 🔄
- ✅ **Fixed Deprecated APIs**: Updated Color properties (`.r/.g/.b` instead of deprecated)
- ✅ **Modern Radio Widgets**: Removed deprecated `onChanged` parameters
- ✅ **Future-Proof Code**: Compatible with latest Flutter 3.0+ APIs
- ✅ **Clean Warnings**: Zero deprecation warnings in console output

**Layout & Rendering Improvements** 📐  
- ✅ **Enhanced Container Rendering**: Better support for complex decoration patterns
- ✅ **Icon Spacing**: 8px padding around icons for better touch targets (44px minimum)
- ✅ **Responsive Layout**: Proper overflow handling with Expanded widgets
- ✅ **Visual Hierarchy**: Consistent spacing system throughout applications
- ✅ **JSON Structure**: Support for sophisticated nested container hierarchies

**Code Quality & Architecture** 🏗️
- ✅ **LoggerUtil Integration**: Better debugging and error reporting
- ✅ **Removed Deprecated Dependencies**: Cleaned up Supabase service dependencies
- ✅ **Enhanced Documentation**: 2 new comprehensive guides (Padding/Margin + Task Manager)
- ✅ **Example Structure**: Organized example applications with clear documentation
- ✅ **Testing & Validation**: JSON syntax validation and error handling improvements

**New Documentation** 📚
- ✅ **[Padding & Margin Guide](./PADDING_MARGIN_GUIDE.md)**: Complete syntax reference with examples
- ✅ **[Task Manager Guide](./TASK_MANAGER_EXAMPLE_GUIDE.md)**: Production app walkthrough
- ✅ **Enhanced README**: Updated with new features and syntax examples
- ✅ **Migration Guide**: How to upgrade from older padding/margin syntax
- ✅ **Best Practices**: Mobile-first design patterns and common pitfall solutions

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

### �� Documentation & Supabase-Only Release

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
