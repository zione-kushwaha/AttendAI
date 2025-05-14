# Routing Guide for Hajiri App

This document explains how to use the routing system in the Hajiri app.

## Overview

The Hajiri app uses a central router (`AppRouter`) to manage all navigation within the app. This approach provides several benefits:

- Consistent route naming
- Easy to maintain and update routes
- Type-safe navigation with arguments
- Simple navigation methods

## Route Names

All route names are defined as constants in the `AppRouter` class:

```dart
static const String home = '/';
static const String students = '/students';
static const String addStudent = '/students/add';
// ... and more
```

## How to Navigate

### Option 1: Using Named Routes (Recommended)

```dart
// Simple navigation
Navigator.of(context).pushNamed(AppRouter.students);

// Navigation with arguments
Navigator.of(context).pushNamed(
  AppRouter.editStudent,
  arguments: studentModel
);
```

### Option 2: Using Helper Methods

The `AppRouter` class provides helper methods for navigation:

```dart
// Simple navigation
AppRouter.navigateToStudents(context);

// Navigation with arguments
AppRouter.navigateToEditStudent(context, studentModel);
```

## Adding New Routes

To add a new route:

1. Add a route name constant in `AppRouter` class
2. Add a case to the `generateRoute` method
3. Add a navigation helper method

Example:

```dart
// 1. Add route name
static const String newFeature = '/new-feature';

// 2. Add case to generateRoute
case newFeature:
  return MaterialPageRoute(builder: (_) => const NewFeatureScreen());

// 3. Add helper method
static void navigateToNewFeature(BuildContext context) {
  Navigator.pushNamed(context, newFeature);
}
```

## Passing Arguments

Arguments can be passed to routes and accessed in the destination screen:

```dart
// Passing arguments
Navigator.of(context).pushNamed(
  AppRouter.editStudent,
  arguments: studentModel
);

// Receiving arguments in build method
Widget build(BuildContext context) {
  final studentModel = ModalRoute.of(context)!.settings.arguments as StudentModel;
  // Use studentModel...
}
```

## Common Patterns

### Replace Current Screen

```dart
Navigator.of(context).pushReplacementNamed(AppRouter.home);
```

### Clear Stack and Show New Screen

```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  AppRouter.home,
  (route) => false
);
```

### Go Back

```dart
Navigator.of(context).pop();
```
