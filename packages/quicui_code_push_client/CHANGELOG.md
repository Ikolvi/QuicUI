# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-11-17

### Added
- **QUICUI01 custom binary patch format** for optimized patch sizes
- Custom patch generation with COPY/ADD operations
- SHA-256 hash validation for patch integrity
- Base64-encoded patch upload system
- In-memory patch storage on backend
- Comprehensive documentation with format specifications
- Complete C++ JNI integration for engine-level patch loading
- Enhanced BsDiffPatcher with native Kotlin implementation
- QuicUICodePushLoader for Java/Kotlin engine integration
- Upload script for large patch files (supports up to ~5MB)
- Gradient UI theme example (v3.0.0 massive update demo)
- Feature cards and animations in test app
- Performance optimization guidelines (Rabin-Karp algorithm)

### Changed
- Updated package version from 0.1.0 to 2.0.0
- Improved patch application with better error handling
- Enhanced backend API with /upload endpoint
- Better architecture documentation
- Updated test app with modern Material 3 design

### Fixed
- XZ compression issues on Android (documented workaround)
- BSDIFF40 format compatibility (now using QUICUI01)
- File upload size limitations (now supports larger patches)
- Backend deployment configuration on Render.com

### Known Issues
- XZ compression not supported on Android (no xz binary)
- Patches must be uploaded uncompressed or with alternative compression
- Backend uses in-memory storage (patches cleared on restart)

### Security
- Enhanced hash validation with SHA-256
- Patch integrity checks before and after application
- Secure HTTPS communication maintained

## [0.1.0] - 2025-11-02

### Added
- Initial release of QuicUI Code Push Client
- Core update checking functionality
- Patch download with progress tracking
- BsDiff patch application
- Signature verification for security
- Automatic rollback on failures
- Android platform support
- Method channel integration with custom engine
- Comprehensive example app
- Documentation and setup guides

### Known Limitations
- Requires custom-built Flutter engine
- Android only (iOS coming soon)
- May violate app store policies (see compliance docs)
- Recommended for enterprise/internal apps only

### Security
- RSA signature verification implemented
- Patch integrity checks
- Secure HTTPS communication with backend

## [Unreleased]

### Planned Features
- iOS platform support
- Desktop platform support (Linux, macOS, Windows)
- Automatic update installation
- A/B testing support
- Staged rollouts
- Update scheduling
- Offline update caching
- Multi-language support
- Enhanced telemetry

---

For more details on each release, see the [GitHub Releases](https://github.com/Ikolvi/QuicUICodepush/releases) page.
