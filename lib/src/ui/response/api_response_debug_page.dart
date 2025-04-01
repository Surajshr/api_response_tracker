import 'dart:convert';
import 'package:api_response_debugger/api_response_debugger.dart';
import 'package:flutter/material.dart';

class ApiResponseDebugPage extends StatefulWidget {
  final String endpoint;

  const ApiResponseDebugPage({
    Key? key,
    required this.endpoint,
  }) : super(key: key);

  @override
  _ApiResponseDebugPageState createState() => _ApiResponseDebugPageState();
}

class _ApiResponseDebugPageState extends State<ApiResponseDebugPage> {
  final ApiResponseTracker _tracker = ApiResponseTracker();
  List<ApiResponseRecord> _responses = [];
  ApiResponseRecord? _selectedResponse;
  ApiResponseRecord? _comparisonResponse;
  JsonDiffResult? _diffResult;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    final responses = await _tracker.getResponsesForEndpoint(widget.endpoint);
    setState(() {
      _responses = responses;
      if (responses.isNotEmpty) {
        _selectedResponse = responses.first;
      }
    });
  }

  void _compareResponses() {
    if (_selectedResponse != null && _comparisonResponse != null) {
      final diff = JsonDiffUtil.compareJson(
        _comparisonResponse!.responseData,
        _selectedResponse!.responseData,
      );
      setState(() {
        _diffResult = diff;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final isTablet = screenWidth > 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          appBar: AppBar(
            title: Text('API Debug: ${widget.endpoint.split('/').last}'),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24.0 : 16.0,
                vertical: isTablet ? 20.0 : 12.0,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: isTablet
                        ? screenHeight * 0.7
                        : (isLandscape
                            ? screenHeight * 0.6
                            : screenHeight * 0.5),
                    child: _responses.isEmpty
                        ? const Center(
                            child:
                                Text('No responses recorded for this endpoint'))
                        : _buildResponsesView(),
                  ),
                  // Add other responsive widgets here
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResponsesView() {
    return Row(
      children: [
        // Response list sidebar
        SizedBox(
          width: 100,
          child: ListView.builder(
            itemCount: _responses.length,
            itemBuilder: (context, index) {
              final response = _responses[index];
              return ListTile(
                title: Text(response.timestamp.toString().substring(0, 16)),
                subtitle: Text(
                    '${response.statusCode} - ${response.parsingStatus.name}'),
                selected: _selectedResponse?.id == response.id,
                onTap: () {
                  setState(() {
                    _selectedResponse = response;
                  });
                },
                onLongPress: () {
                  setState(() {
                    _comparisonResponse = response;
                    _compareResponses();
                  });
                },
                tileColor: _comparisonResponse?.id == response.id
                    ? Colors.amber.withOpacity(0.3)
                    : null,
              );
            },
          ),
        ),
        // Vertical divider
        Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(-2, 0),
              ),
            ],
          ),
          child: VerticalDivider(
            width: 1,
            color: Colors.black12,
            endIndent: 30,
          ),
        ),
        // Response details
        Expanded(
          child: _selectedResponse == null
              ? const Center(child: Text('Select a response'))
              : _buildResponseDetails(),
        ),
      ],
    );
  }

  Widget _buildResponseDetails() {
    if (_selectedResponse == null) return const SizedBox.shrink();

    // Build the tab list first
    final List<Widget> tabs = [
      const Tab(text: 'Response'),
    ];

    // Build the tab content list
    final List<Widget> tabViews = [
      _buildJsonViewer(_selectedResponse!.responseData),
    ];

    // Add model comparison tab if model structure is available
    if (_selectedResponse!.modelStructure != null) {
      tabs.add(const Tab(text: 'Model Comparison'));
      tabViews.add(ModelComparisonView(
        modelStructureJson: _selectedResponse!.modelStructure,
        responseJson: _selectedResponse!.responseData,
      ));
    }

    // Conditionally add the error tab
    if (_selectedResponse!.parsingStatus == ParsingStatus.failure) {
      tabs.add(const Tab(text: 'Error'));
      tabViews.add(_buildErrorView());
    }

    // Conditionally add the comparison tab
    if (_diffResult != null) {
      tabs.add(const Tab(text: 'Comparison'));
      tabViews.add(_buildDiffView());
    }

    return DefaultTabController(
      length: tabs.length, // Now this will always match the number of tabs
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(tabs: tabs),
          Expanded(
            child: TabBarView(children: tabViews),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonViewer(String jsonStr) {
    try {
      final jsonObj = json.decode(jsonStr);
      final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonObj);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HighlightView(
          prettyJson,
          language: 'json',
          theme: githubTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
          ),
        ),
      );
    } catch (e) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text('Invalid JSON: $jsonStr\n\nError: $e'),
      );
    }
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parsing Error:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                  )),
          const SizedBox(height: 8),
          Text(_selectedResponse?.parsingError ?? 'Unknown error'),
          const SizedBox(height: 16),
          Text('Stack Trace:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: SelectableText(
              _selectedResponse?.stackTrace ?? 'No stack trace available',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffView() {
    if (_diffResult == null)
      return const Center(child: Text('No comparison data'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Comparison between:',
              style: Theme.of(context).textTheme.titleMedium),
          Text(
              '• ${_comparisonResponse?.timestamp.toString().substring(0, 16)} (base)'),
          Text(
              '• ${_selectedResponse?.timestamp.toString().substring(0, 16)} (current)'),
          const Divider(),
          if (!_diffResult!.hasDifferences)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No differences found',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (_diffResult!.additions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Additions:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildJsonViewer(json.encode(_diffResult!.additions)),
          ],
          if (_diffResult!.removals.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Removals:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildJsonViewer(json.encode(_diffResult!.removals)),
          ],
          if (_diffResult!.changes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Changes:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildJsonViewer(json.encode(_diffResult!.changes)),
          ],
        ],
      ),
    );
  }
}
