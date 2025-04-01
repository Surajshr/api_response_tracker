import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

enum ParsingStatus {
  success,
  failure,
  notAttempted,
}

enum ApiStatus {
  success,
  failure,
}

class ApiResponseRecord {
  final int id;
  final String endpoint;
  final int statusCode;
  final String responseData;
  final ParsingStatus parsingStatus;
  final ApiStatus apiStatus;
  final String? parsingError;
  final String? stackTrace;
  final String? modelStructure;
  final DateTime timestamp;

  ApiResponseRecord({
    required this.id,
    required this.endpoint,
    required this.statusCode,
    required this.responseData,
    required this.parsingStatus,
    required this.apiStatus,
    this.parsingError,
    this.stackTrace,
    this.modelStructure,
    required this.timestamp,
  });

  factory ApiResponseRecord.fromMap(Map<String, dynamic> map) {
    return ApiResponseRecord(
      id: map['id'] as int,
      endpoint: map['endpoint'] as String,
      statusCode: map['status_code'] as int,
      responseData: map['response_data'] as String,
      parsingStatus: ParsingStatus.values.firstWhere(
          (e) => e.toString() == map['parsing_status'],
          orElse: () => ParsingStatus.notAttempted),
      apiStatus: ApiStatus.values.firstWhere(
          (e) => e.toString() == map['api_status'],
          orElse: () => ApiStatus.failure),
      parsingError: map['parsing_error'] as String?,
      stackTrace: map['stack_trace'] as String?,
      modelStructure: map['model_structure'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'endpoint': endpoint,
      'status_code': statusCode,
      'response_data': responseData,
      'parsing_status': parsingStatus.toString(),
      'api_status': apiStatus.toString(),
      'parsing_error': parsingError,
      'stack_trace': stackTrace,
      'model_structure': modelStructure,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ApiResponseTracker {
  static final ApiResponseTracker _instance = ApiResponseTracker._internal();
  static Database? _database;

  factory ApiResponseTracker() {
    return _instance;
  }

  ApiResponseTracker._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'api_responses.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE api_responses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            status_code INTEGER NOT NULL,
            response_data TEXT NOT NULL,
            parsing_status TEXT NOT NULL,
            api_status TEXT NOT NULL,
            parsing_error TEXT,
            stack_trace TEXT,
            model_structure TEXT,
            timestamp TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE api_responses ADD COLUMN model_structure TEXT;');
        }
      },
    );
  }

  Future<void> storeApiResponse({
    required String endpoint,
    required int statusCode,
    required dynamic responseData,
    required ParsingStatus parsingStatus,
    ApiStatus apiStatus = ApiStatus.success,
    String? parsingError,
    String? stackTrace,
    String? modelStructure,
  }) async {
    try {
      final db = await database;
      String jsonData;

      if (responseData is Map) {
        jsonData = jsonEncode(responseData);
      } else if (responseData is String) {
        jsonData = responseData;
      } else {
        jsonData = jsonEncode({"raw_data": responseData.toString()});
      }

      // Check for existing responses with the same endpoint and status
      final existingResponses = await db.query(
        'api_responses',
        where: 'endpoint = ? AND status_code = ? AND parsing_status = ?',
        whereArgs: [endpoint, statusCode, parsingStatus.toString()],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      // If existing response found with same characteristics, delete it
      if (existingResponses.isNotEmpty) {
        final existingId = existingResponses.first['id'] as int;
        await db.delete(
          'api_responses',
          where: 'id = ?',
          whereArgs: [existingId],
        );

        // PrintUtil.printLog(
        //   tag: 'ApiResponseTracker',
        //   message: 'Removed previous response for $endpoint with same status',
        // );
      }

      // Insert the new response
      await db.insert(
        'api_responses',
        {
          'endpoint': endpoint,
          'status_code': statusCode,
          'response_data': jsonData,
          'parsing_status': parsingStatus.toString(),
          'api_status': apiStatus.toString(),
          'parsing_error': parsingError,
          'stack_trace': stackTrace,
          'model_structure': modelStructure,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // PrintUtil.printLog(
      //   tag: 'ApiResponseTracker',
      //   message: 'Stored API response for $endpoint',
      // );
    } catch (e) {
      // PrintUtil.printLog(
      //   tag: 'ApiResponseTracker',
      //   message: 'Failed to store API response: $e',
      // );
    }
  }

  Future<List<ApiResponseRecord>> getResponsesForEndpoint(
      String endpoint) async {
    final db = await database;
    final results = await db.query(
      'api_responses',
      where: 'endpoint = ?',
      whereArgs: [endpoint],
      orderBy: 'timestamp DESC',
    );

    return results.map((map) => ApiResponseRecord.fromMap(map)).toList();
  }

  Future<List<ApiResponseRecord>> getFailedParsingResponses() async {
    final db = await database;
    final results = await db.query(
      'api_responses',
      where: 'parsing_status = ?',
      whereArgs: [ParsingStatus.failure.toString()],
      orderBy: 'timestamp DESC',
    );

    return results.map((map) => ApiResponseRecord.fromMap(map)).toList();
  }

  Future<ApiResponseRecord?> getLatestResponseForEndpoint(
      String endpoint) async {
    final db = await database;
    final results = await db.query(
      'api_responses',
      where: 'endpoint = ?',
      whereArgs: [endpoint],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ApiResponseRecord.fromMap(results.first);
  }

  Future<ApiResponseRecord?> getLatestSuccessfulResponseForEndpoint(
      String endpoint) async {
    final db = await database;
    final results = await db.query(
      'api_responses',
      where: 'endpoint = ? AND parsing_status = ?',
      whereArgs: [endpoint, ParsingStatus.success.toString()],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return ApiResponseRecord.fromMap(results.first);
  }
}
