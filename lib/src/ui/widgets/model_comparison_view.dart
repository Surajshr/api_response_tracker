import 'dart:convert';
import 'package:api_response_debugger/api_response_debugger.dart';
import 'package:flutter/material.dart';

class ModelComparisonView extends StatelessWidget {
  final String? modelStructureJson;
  final String responseJson;

  const ModelComparisonView({
    Key? key,
    required this.modelStructureJson,
    required this.responseJson,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (modelStructureJson == null) {
      return const Center(
        child: Text('No model structure available for comparison'),
      );
    }

    try {
      // Parse the model structure and API response
      final modelStructure = ModelStructure.fromJson(modelStructureJson!);
      final responseData = json.decode(responseJson) as Map<String, dynamic>;

      // Generate the type comparison results
      final results = _compareModelWithResponse(modelStructure, responseData);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model-API Comparison',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Model: ${modelStructure.modelName}'),
            const SizedBox(height: 16),

            if (results.isEmpty)
              const Text(
                'All fields match between model and API response',
                style: TextStyle(color: Colors.green),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mismatches Found:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...results.map(
                    _buildMismatchItem,
                  ),
                ],
              ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Show the model structure
            Text(
              'Expected Model Structure:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildModelStructureView(modelStructure),

            const SizedBox(height: 16),

            // Show a sample valid JSON
            Text(
              'Sample Valid JSON:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildSampleJsonView(modelStructure),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Text('Error comparing model and API response: $e'),
      );
    }
  }

  Widget _buildMismatchItem(TypeMismatch mismatch) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Field: ${mismatch.fieldPath}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text('Expected type: ${mismatch.expectedType}'),
          Text('Actual type: ${mismatch.actualType}'),
          if (mismatch.isNullabilityIssue)
            const Text(
              'Issue: Field is required but received null',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          if (mismatch.isMissingField)
            const Text(
              'Issue: Field is missing in API response',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _buildModelStructureView(ModelStructure modelStructure) {
    final buffer = StringBuffer();
    buffer.writeln('class ${modelStructure.modelName} {');

    // Add fields
    for (final field in modelStructure.fields) {
      buffer.write('  ');
      buffer.write(field.type);
      if (field.isNullable) buffer.write('?');
      buffer.write(' ');
      buffer.writeln('${field.name};');
    }

    buffer.writeln('}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        buffer.toString(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSampleJsonView(ModelStructure modelStructure) {
    final sampleJson = _generateSampleJson(modelStructure);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(sampleJson);

    return HighlightView(
      prettyJson,
      language: 'json',
      theme: githubTheme,
      padding: const EdgeInsets.all(12),
      textStyle: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
      ),
    );
  }

  Map<String, dynamic> _generateSampleJson(ModelStructure modelStructure) {
    final result = <String, dynamic>{};

    for (final field in modelStructure.fields) {
      result[field.name] = _getSampleValueForType(field.type, field.isNullable);
    }

    return result;
  }

  dynamic _getSampleValueForType(String type, bool isNullable) {
    if (isNullable) return null;

    switch (type.toLowerCase()) {
      case 'string':
        return 'sample_string';
      case 'int':
        return 42;
      case 'double':
      case 'num':
        return 42.5;
      case 'bool':
        return true;
      case 'list':
      case 'list<dynamic>':
        return [];
      case 'map':
      case 'map<string, dynamic>':
        return {};
      default:
        if (type.startsWith('List<')) {
          return [];
        }
        return {};
    }
  }
}

class TypeMismatch {
  final String fieldPath;
  final String expectedType;
  final String actualType;
  final bool isNullabilityIssue;
  final bool isMissingField;

  TypeMismatch({
    required this.fieldPath,
    required this.expectedType,
    required this.actualType,
    this.isNullabilityIssue = false,
    this.isMissingField = false,
  });
}

List<TypeMismatch> _compareModelWithResponse(
    ModelStructure modelStructure, Map<String, dynamic> responseData) {
  final mismatches = <TypeMismatch>[];

  for (final field in modelStructure.fields) {
    final fieldName = field.name;

    // Check if field exists in response
    if (!responseData.containsKey(fieldName)) {
      // Field is missing
      mismatches.add(TypeMismatch(
        fieldPath: fieldName,
        expectedType: field.type,
        actualType: 'missing',
        isMissingField: true,
      ));
      continue;
    }

    final value = responseData[fieldName];

    // Check for null values in non-nullable fields
    if (!field.isNullable && value == null) {
      mismatches.add(TypeMismatch(
        fieldPath: fieldName,
        expectedType: '${field.type} (non-nullable)',
        actualType: 'null',
        isNullabilityIssue: true,
      ));
      continue;
    }

    // Skip null checks for nullable fields
    if (value == null) continue;

    // Check type matches
    final actualType = _getTypeName(value);
    final expectedType = _normalizeTypeName(field.type);

    if (!_typesAreCompatible(expectedType, actualType)) {
      mismatches.add(TypeMismatch(
        fieldPath: fieldName,
        expectedType: field.type,
        actualType: actualType,
      ));
    }

    // Check nested fields if applicable
    if (field.subFields.isNotEmpty && value is Map<String, dynamic>) {
      final nestedMismatches = field.subFields
          .where((subField) =>
              !_checkFieldValueMatch(subField, value[subField.name]))
          .map((subField) => TypeMismatch(
                fieldPath: '$fieldName.${subField.name}',
                expectedType: subField.type,
                actualType: value[subField.name] == null
                    ? 'null'
                    : _getTypeName(value[subField.name]),
                isNullabilityIssue:
                    !subField.isNullable && value[subField.name] == null,
              ))
          .toList();

      mismatches.addAll(nestedMismatches);
    }
  }

  return mismatches;
}

bool _checkFieldValueMatch(ModelField field, dynamic value) {
  if (!field.isNullable && value == null) return false;
  if (value == null) return true;

  final actualType = _getTypeName(value);
  final expectedType = _normalizeTypeName(field.type);

  return _typesAreCompatible(expectedType, actualType);
}

String _getTypeName(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return 'String';
  if (value is int) return 'int';
  if (value is double) return 'double';
  if (value is bool) return 'bool';
  if (value is List) {
    return 'List<${value.isEmpty ? 'dynamic' : _getTypeName(value.first)}>';
  }
  if (value is Map) {
    return 'Map<${value.isEmpty ? 'String, dynamic' : 'String, ${_getTypeName(value.values.first)}'}>';
  }
  return value.runtimeType.toString();
}

String _normalizeTypeName(String typeName) {
  switch (typeName.toLowerCase()) {
    case 'string':
      return 'String';
    case 'int':
      return 'int';
    case 'double':
      return 'double';
    case 'num':
      return 'num';
    case 'bool':
      return 'bool';
    case 'list':
      return 'List<dynamic>';
    case 'map':
      return 'Map<String, dynamic>';
    default:
      return typeName;
  }
}

bool _typesAreCompatible(String expectedType, String actualType) {
  // Exact match
  if (expectedType == actualType) return true;

  // Numeric types compatibility
  if ((expectedType == 'num' || expectedType == 'double') &&
      (actualType == 'int' || actualType == 'double' || actualType == 'num')) {
    return true;
  }

  // List compatibility (basic check)
  if (expectedType.startsWith('List<') && actualType.startsWith('List<')) {
    return true; // Simplified check - in reality you'd want to check item types too
  }

  // Map compatibility (basic check)
  if (expectedType.startsWith('Map<') && actualType.startsWith('Map<')) {
    return true; // Simplified check
  }

  return false;
}
