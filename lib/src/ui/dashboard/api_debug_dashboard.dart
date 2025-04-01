import 'package:api_response_debugger/api_response_debugger.dart';
import 'package:flutter/material.dart';

class ApiDebugDashboard extends StatefulWidget {
  const ApiDebugDashboard({Key? key}) : super(key: key);

  @override
  State<ApiDebugDashboard> createState() => _ApiDebugDashboardState();
}

class _ApiDebugDashboardState extends State<ApiDebugDashboard> {
  final ApiResponseTracker _tracker = ApiResponseTracker();
  List<ApiResponseRecord> _failedResponses = [];
  Set<String> _uniqueEndpoints = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFailedResponses();
  }

  Future<void> _loadFailedResponses() async {
    setState(() {
      _isLoading = true;
    });

    final failedResponses = await _tracker.getFailedParsingResponses();
    final endpoints = <String>{};

    for (final response in failedResponses) {
      endpoints.add(response.endpoint);
    }

    setState(() {
      _failedResponses = failedResponses;
      _uniqueEndpoints = endpoints;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all logs',
            onPressed: () => _showClearLogsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadFailedResponses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_failedResponses.isEmpty) {
      return const Center(
        child: Text('No API responses with parsing issues found'),
      );
    }

    return ListView(
      children: [
        // Summary section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API Parsing Issues Summary',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Total Issues: ${_failedResponses.length}'),
                  Text('Affected Endpoints: ${_uniqueEndpoints.length}'),
                ],
              ),
            ),
          ),
        ),

        // Endpoints list
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Endpoints with Parsing Issues',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),

        ...List.generate(_uniqueEndpoints.length, (index) {
          final endpoint = _uniqueEndpoints.elementAt(index);
          final endpointResponses =
              _failedResponses.where((r) => r.endpoint == endpoint).toList();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              title: Text(endpoint),
              subtitle: Text('${endpointResponses.length} parsing issues'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ApiResponseDebugPage(endpoint: endpoint),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Future<void> _showClearLogsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text(
          'Are you sure you want to clear all API response logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      // Clear the database
      final db = await _tracker.database;
      await db.delete('api_responses');

      // Refresh the UI
      await _loadFailedResponses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All logs cleared successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
