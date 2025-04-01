import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HighlightView extends StatelessWidget {
  final String source;
  final String language;
  final Map<String, TextStyle> theme;
  final EdgeInsetsGeometry padding;
  final TextStyle textStyle;

  const HighlightView(
    this.source, {
    Key? key,
    required this.language,
    required this.theme,
    this.padding = EdgeInsets.zero,
    required this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: theme['root']?.backgroundColor ?? Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              SelectableText.rich(
                _buildTextSpan(source, language),
                style: textStyle,
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: source));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  tooltip: 'Copy to clipboard',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildTextSpan(String source, String language) {
    if (language == 'json') {
      return _highlightJson(source);
    } else {
      // Default basic highlighting for other languages
      return TextSpan(text: source, style: textStyle);
    }
  }

  TextSpan _highlightJson(String jsonStr) {
    final List<TextSpan> spans = [];
    int index = 0;

    // Simple regex patterns for JSON
    final stringPattern = RegExp(r'"(?:\\.|[^"\\])*"');
    final numberPattern = RegExp(r'\b\d+(?:\.\d+)?\b');
    final keywordPattern = RegExp(r'\b(true|false|null)\b');
    final bracketPattern = RegExp(r'[\[\]{}]');
    final colonCommaPattern = RegExp(r'[:,]');

    while (index < jsonStr.length) {
      final remaining = jsonStr.substring(index);

      // Check for string (which could be a key)
      final stringMatch = stringPattern.matchAsPrefix(remaining);
      if (stringMatch != null) {
        final value = stringMatch.group(0)!;
        // Check if this string is a key (followed by colon)
        final afterString = index + value.length < jsonStr.length
            ? jsonStr.substring(index + value.length).trimLeft()
            : '';
        if (afterString.startsWith(':')) {
          // This is a key
          spans.add(TextSpan(
              text: value,
              style: theme['attr'] ?? const TextStyle(color: Colors.purple)));
        } else {
          // This is a string value
          spans.add(TextSpan(
              text: value,
              style: theme['string'] ?? const TextStyle(color: Colors.green)));
        }
        index += value.length;
        continue;
      }

      // Check for number
      final numberMatch = numberPattern.matchAsPrefix(remaining);
      if (numberMatch != null) {
        spans.add(TextSpan(
          text: numberMatch.group(0),
          style: theme['number'] ?? const TextStyle(color: Colors.blue),
        ));
        index += numberMatch.group(0)!.length;
        continue;
      }

      // Check for keywords
      final keywordMatch = keywordPattern.matchAsPrefix(remaining);
      if (keywordMatch != null) {
        final keyword = keywordMatch.group(0)!;
        TextStyle? style;

        if (keyword == 'true' || keyword == 'false') {
          style = theme['literal'] ?? const TextStyle(color: Colors.orange);
        } else {
          style = theme['keyword'] ?? const TextStyle(color: Colors.blue);
        }

        spans.add(TextSpan(text: keyword, style: style));
        index += keyword.length;
        continue;
      }

      // Check for brackets
      final bracketMatch = bracketPattern.matchAsPrefix(remaining);
      if (bracketMatch != null) {
        spans.add(TextSpan(
          text: bracketMatch.group(0),
          style: theme['punctuation'] ?? const TextStyle(color: Colors.grey),
        ));
        index += bracketMatch.group(0)!.length;
        continue;
      }

      // Check for colons and commas
      final colonCommaMatch = colonCommaPattern.matchAsPrefix(remaining);
      if (colonCommaMatch != null) {
        spans.add(TextSpan(
          text: colonCommaMatch.group(0),
          style: theme['punctuation'] ?? const TextStyle(color: Colors.grey),
        ));
        index += colonCommaMatch.group(0)!.length;
        continue;
      }

      // Default case - just add the character as is
      spans.add(TextSpan(text: jsonStr[index]));
      index++;
    }

    return TextSpan(children: spans);
  }
}

// Define a GitHub-like theme
Map<String, TextStyle> githubTheme = {
  'root': const TextStyle(backgroundColor: Color(0xffffffff)),
  'string': const TextStyle(color: Color(0xff0a3069)),
  'number': const TextStyle(color: Color(0xff005cc5)),
  'attr': const TextStyle(color: Color(0xff6f42c1)),
  'keyword': const TextStyle(color: Color(0xff0086b3)),
  'literal': const TextStyle(color: Color(0xff0086b3)),
  'punctuation': const TextStyle(color: Color(0xff24292e)),
};
