# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application named "flutter_thundertrack_stormg" - currently a new Flutter project with the default counter app template. The project supports multiple platforms (Android, iOS, Web, Linux, macOS, Windows) and follows standard Flutter project structure.

## Essential Commands

### Development
- `flutter run` - Run the app in development mode (supports hot reload)
- `flutter run -d web` - Run on web browser
- `flutter run -d chrome` - Run specifically on Chrome
- `flutter devices` - List available devices/simulators

### Build
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app (requires macOS and Xcode)
- `flutter build web` - Build web version
- `flutter build windows` - Build Windows desktop app
- `flutter build linux` - Build Linux desktop app
- `flutter build macos` - Build macOS desktop app

### Quality Assurance
- `flutter analyze` - Run static analysis (configured via analysis_options.yaml)
- `flutter test` - Run all tests
- `flutter test test/widget_test.dart` - Run specific test file

### Dependencies
- `flutter pub get` - Install dependencies from pubspec.yaml
- `flutter pub upgrade` - Upgrade dependencies
- `flutter pub outdated` - Check for outdated dependencies

### Maintenance
- `flutter clean` - Clean build artifacts
- `flutter doctor` - Check Flutter installation and dependencies

## Architecture

This is currently a basic Flutter project with:

- **Entry Point**: `lib/main.dart` contains the main application with MyApp (root widget) and MyHomePage (stateful counter demo)
- **Testing**: Basic widget test in `test/widget_test.dart` 
- **Configuration**: Standard Flutter analysis rules via `analysis_options.yaml` using `package:flutter_lints/flutter.yaml`
- **Dependencies**: Only core Flutter SDK and cupertino_icons, with flutter_lints for development

## Platform-Specific Notes

The project includes platform folders for:
- `android/` - Android-specific configuration and build files
- `ios/` - iOS-specific configuration and Xcode project files  
- `web/` - Web-specific assets and configuration
- `linux/`, `macos/`, `windows/` - Desktop platform configurations

## Development Environment

- **Dart SDK**: ^3.8.1 (as specified in pubspec.yaml)
- **Linting**: Uses flutter_lints ^5.0.0 with default Flutter linting rules
- **Hot Reload**: Supported via `flutter run` for rapid development