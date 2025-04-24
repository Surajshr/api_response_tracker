import 'package:flutter_test/flutter_test.dart';
import 'package:api_response_debugger/api_response_debugger.dart';

void main() {
  group('ApiResponseTracker Tests', () {
    late ApiResponseTracker tracker;

    setUp(() {
      tracker = ApiResponseTracker();
    });

    test('ApiResponseTracker instance should be created', () {
      expect(tracker, isNotNull);
    });

    test('ParsingStatus enum should have correct values', () {
      expect(ParsingStatus.values.length, equals(3));
      expect(ParsingStatus.success, isNotNull);
      expect(ParsingStatus.failure, isNotNull);
      expect(ParsingStatus.notAttempted, isNotNull);
    });

    test('ApiStatus enum should have correct values', () {
      expect(ApiStatus.values.length, equals(2));
      expect(ApiStatus.success, isNotNull);
      expect(ApiStatus.failure, isNotNull);
    });
  });

  group('JsonDiffUtil Tests', () {
    test('compareJson should handle null inputs', () {
      final result = JsonDiffUtil.compareJson('null', 'null');
      expect(result.hasDifferences, isFalse);
    });

    test('compareJson should detect simple changes', () {
      final result = JsonDiffUtil.compareJson(
        '{"name": "old"}',
        '{"name": "new"}',
      );
      expect(result.hasDifferences, isTrue);
      expect(result.changes, isNotEmpty);
    });
  });
}
