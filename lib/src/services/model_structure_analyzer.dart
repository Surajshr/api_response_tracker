import 'dart:convert';

class ModelField {
  final String name;
  final String type;
  final bool isNullable;
  final List<ModelField> subFields;

  ModelField({
    required this.name,
    required this.type,
    required this.isNullable,
    this.subFields = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isNullable': isNullable,
      'subFields': subFields.map((field) => field.toMap()).toList(),
    };
  }

  factory ModelField.fromMap(Map<String, dynamic> map) {
    return ModelField(
      name: map['name'] as String,
      type: map['type'] as String,
      isNullable: map['isNullable'] as bool,
      subFields: (map['subFields'] as List? ?? [])
          .map((e) => ModelField.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  String toString() {
    return '$name: ${isNullable ? '$type?' : type}';
  }
}

class ModelStructure {
  final String modelName;
  final List<ModelField> fields;

  ModelStructure({
    required this.modelName,
    required this.fields,
  });

  Map<String, dynamic> toMap() {
    return {
      'modelName': modelName,
      'fields': fields.map((field) => field.toMap()).toList(),
    };
  }

  factory ModelStructure.fromMap(Map<String, dynamic> map) {
    return ModelStructure(
      modelName: map['modelName'] as String,
      fields: (map['fields'] as List? ?? [])
          .map((e) => ModelField.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory ModelStructure.fromJson(String json) {
    return ModelStructure.fromMap(jsonDecode(json) as Map<String, dynamic>);
  }
}

class ModelStructureAnalyzer {
  // Extract model structure using a manual approach without reflection
  static ModelStructure analyzeModel<T>(T model) {
    final modelName = T.toString();
    final modelMap = _convertToMap(model);
    final fields = <ModelField>[];

    modelMap.forEach((key, value) {
      String type = value?.runtimeType.toString() ?? 'dynamic';
      bool isNullable = value == null;
      List<ModelField> subFields = [];

      // Check for nested objects
      if (value != null && value is Map) {
        final nestedMap = Map<String, dynamic>.from(value);
        nestedMap.forEach((subKey, subValue) {
          String subType = subValue?.runtimeType.toString() ?? 'dynamic';
          subFields.add(ModelField(
            name: subKey,
            type: subType,
            isNullable: subValue == null,
          ));
        });
      }

      fields.add(ModelField(
        name: key,
        type: type,
        isNullable: isNullable,
        subFields: subFields,
      ));
    });

    return ModelStructure(
      modelName: modelName,
      fields: fields,
    );
  }

  // Helper method to convert model to map
  static Map<String, dynamic> _convertToMap<T>(T model) {
    if (model == null) return {};

    // Try jsonEncode/decode if the model supports it
    try {
      final jsonStr = jsonEncode(model);
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      // If model doesn't support JSON serialization, try to use its toString
      try {
        // Some models have a toString that gives useful data
        final str = model.toString();
        if (str.startsWith('{') && str.endsWith('}')) {
          // Try to parse it as JSON
          return jsonDecode(str) as Map<String, dynamic>;
        }
      } catch (_) {}
    }

    // Last resort: empty map
    return {};
  }

  // Extract model info from error message
  static String extractExpectedStructureFromError(
      Object error, String modelType) {
    final errorStr = error.toString();
    final fields = <ModelField>[];

    // Common error patterns for type mismatches
    final typeErrorRegex =
        RegExp("type '([^']+)' is not a subtype of type '([^']+)'");
    final missingFieldRegex = RegExp("The getter '([^']+)' was called on null");
    final jsonKeyRegex =
        RegExp("'([^']+)': '([^']+)' is not of type '([^']+)'");

    // Check for type mismatches
    final typeMatches = typeErrorRegex.allMatches(errorStr);
    for (final match in typeMatches) {
      if (match.groupCount >= 2) {
        fields.add(ModelField(
          name: 'unknown (type error)',
          type: match.group(2) ?? 'unknown',
          isNullable: false,
        ));
      }
    }

    // Check for missing required fields
    final missingMatches = missingFieldRegex.allMatches(errorStr);
    for (final match in missingMatches) {
      if (match.groupCount >= 1) {
        fields.add(ModelField(
          name: match.group(1) ?? 'unknown',
          type: 'non-nullable',
          isNullable: false,
        ));
      }
    }

    // Check for JSON key type mismatches
    final jsonKeyMatches = jsonKeyRegex.allMatches(errorStr);
    for (final match in jsonKeyMatches) {
      if (match.groupCount >= 3) {
        fields.add(ModelField(
          name: match.group(1) ?? 'unknown',
          type: match.group(3) ?? 'unknown',
          isNullable: false,
        ));
      }
    }

    // If no specific fields found, create a generic model structure
    if (fields.isEmpty) {
      fields.add(ModelField(
        name: 'error_info',
        type: 'unknown',
        isNullable: false,
      ));
    }

    return ModelStructure(
      modelName: modelType,
      fields: fields,
    ).toJson();
  }
}
