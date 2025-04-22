<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# API Response Debugger
A Flutter package for debugging API responses with advanced visualization and analysis tools.

## Overview
API Response Debugger is a powerful debugging tool that helps track, analyze, and debug API responses in Flutter applications. It provides local storage of API responses, comparison tools, and a visual interface for inspecting API data and parsing issues.

## Features
- 📝 Local storage of API responses
- 🔍 Response history tracking and viewing
- 🔄 JSON diff visualization
- ⚠️ Parsing error analysis
- 📊 Model-Response structure comparison
- 🎯 Debug dashboard UI
- 📱 Response details viewer
- 🚨 Error tracking and stack trace capture

## Getting started

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  api_response_debugger: ^0.0.1
```

Required dependencies will be automatically included:
- sqflite: ^2.3.0
- path: ^1.8.3
- dio: ^5.0.0
- dartz: ^0.10.1

## Usage

### 1. Initialize the tracker

```dart
final apiTracker = ApiResponseTracker();
```

### 2. Track API responses

```dart
try {
  final response = await dio.get('/endpoint');
  
  await apiTracker.storeApiResponse(
    endpoint: '/endpoint',
    statusCode: response.statusCode ?? 0,
    responseData: response.data,
    parsingStatus: ParsingStatus.success,
    apiStatus: ApiStatus.success,
  );
} catch (e, stackTrace) {
  await apiTracker.storeApiResponse(
    endpoint: '/endpoint',
    statusCode: 500,
    responseData: e.toString(),
    parsingStatus: ParsingStatus.failure,
    apiStatus: ApiStatus.failure,
    parsingError: e.toString(),
    stackTrace: stackTrace.toString(),
  );
}
```

### 3. Add debug dashboard

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const ApiDebugDashboard()),
);
```

## Core Features

### Response Tracking
- Automatic storage of API responses
- Parsing status tracking
- Error and stack trace capture
- Response history per endpoint

### Debug Dashboard
The `ApiDebugDashboard` provides:
- Overview of all tracked endpoints
- Failed response highlighting
- Response history viewing
- JSON comparison tools

### Response Analysis
- JSON diff visualization
- Model structure comparison
- Type mismatch detection
- Parsing error analysis

## API Reference

### ApiResponseTracker
Main class for managing API responses:

```dart
// Store a response
await apiTracker.storeApiResponse(
  endpoint: endpoint,
  statusCode: statusCode,
  responseData: responseData,
  parsingStatus: parsingStatus,
);

// Get responses for endpoint
final responses = await apiTracker.getResponsesForEndpoint(endpoint);

// Get failed parsing responses
final failedResponses = await apiTracker.getFailedParsingResponses();

// Get latest response
final latest = await apiTracker.getLatestResponseForEndpoint(endpoint);
```

### Debug UI Components

1. `ApiDebugDashboard`: Main debugging interface
```dart
const ApiDebugDashboard();
```

2. `ApiResponseDebugPage`: Detailed response view
```dart
ApiResponseDebugPage(endpoint: 'your_endpoint');
```

3. `ModelComparisonView`: Compare model and response structures
```dart
ModelComparisonView(
  modelStructureJson: modelJson,
  responseJson: responseJson,
);
```

## Best Practices

1. Development Only Usage
```dart
if (kDebugMode) {
  // Initialize API Response Debugger
}
```

2. Clean Database Regularly
```dart
// Implement periodic cleanup based on your needs
```

3. Meaningful Endpoint Names
Use clear, descriptive endpoint paths for better debugging:
```dart
"/users/profile" instead of "/api/v1/u/p"
```

## Troubleshooting

### Database Issues
- Ensure proper database initialization
- Check write permissions
- Verify storage space availability

### Response Tracking Issues
- Verify response data format
- Check endpoint paths
- Ensure proper error handling

### UI Issues
- Verify BuildContext availability
- Check navigation state
- Ensure proper widget tree structure

## Requirements
- Flutter ≥ 3.0.0
- Dart ≥ 3.0.0
- iOS 11.0 or above
- Android 5.0 (API 21) or above

## Additional Information
- [Report Issues](https://github.com/Surajshr/api_response_tracker/issues)
- [Request Features](https://github.com/Surajshr/api_response_tracker/issues/new)
- [Documentation](https://github.com/Surajshr/api_response_tracker/wiki)

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
