import 'package:flutter/material.dart';
import 'package:api_response_debugger/api_response_debugger.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Response Debugger Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiResponseTracker _tracker = ApiResponseTracker();
  final Dio _dio = Dio();

  Future<void> _makeApiCall() async {
    try {
      final response =
          await _dio.get('https://jsonplaceholder.typicode.com/posts/1');

      await _tracker.storeApiResponse(
        endpoint: '/posts/1',
        statusCode: response.statusCode ?? 0,
        responseData: response.data,
        parsingStatus: ParsingStatus.success,
        apiStatus: ApiStatus.success,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API call successful')),
        );
      }
    } catch (e, stackTrace) {
      await _tracker.storeApiResponse(
        endpoint: '/posts/1',
        statusCode: 500,
        responseData: e.toString(),
        parsingStatus: ParsingStatus.failure,
        apiStatus: ApiStatus.failure,
        parsingError: e.toString(),
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API call failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Response Debugger Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _makeApiCall,
              child: const Text('Make API Call'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ApiDebugDashboard(),
                  ),
                );
              },
              child: const Text('Open Debug Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
