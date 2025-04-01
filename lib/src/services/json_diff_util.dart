import 'dart:convert';

class JsonDiffResult {
  final Map<String, dynamic> additions;
  final Map<String, dynamic> removals;
  final Map<String, dynamic> changes;
  final List<String> pathsWithDifferences;

  JsonDiffResult({
    required this.additions,
    required this.removals,
    required this.changes,
    required this.pathsWithDifferences,
  });

  bool get hasDifferences =>
      additions.isNotEmpty || removals.isNotEmpty || changes.isNotEmpty;
}

class JsonDiffUtil {
  static JsonDiffResult compareJson(String oldJson, String newJson) {
    Map<String, dynamic> oldMap;
    Map<String, dynamic> newMap;

    try {
      oldMap = jsonDecode(oldJson) as Map<String, dynamic>;
    } catch (e) {
      oldMap = {'raw_data': oldJson};
    }

    try {
      newMap = jsonDecode(newJson) as Map<String, dynamic>;
    } catch (e) {
      newMap = {'raw_data': newJson};
    }

    final additions = <String, dynamic>{};
    final removals = <String, dynamic>{};
    final changes = <String, dynamic>{};
    final pathsWithDifferences = <String>[];

    _compareObjects(
        oldMap, newMap, '', additions, removals, changes, pathsWithDifferences);

    return JsonDiffResult(
      additions: additions,
      removals: removals,
      changes: changes,
      pathsWithDifferences: pathsWithDifferences,
    );
  }

  static void _compareObjects(
    Map<String, dynamic> oldObj,
    Map<String, dynamic> newObj,
    String path,
    Map<String, dynamic> additions,
    Map<String, dynamic> removals,
    Map<String, dynamic> changes,
    List<String> pathsWithDifferences,
  ) {
    // Find additions (keys in new but not in old)
    for (final key in newObj.keys) {
      if (!oldObj.containsKey(key)) {
        final currentPath = path.isEmpty ? key : '$path.$key';
        additions[currentPath] = newObj[key];
        pathsWithDifferences.add(currentPath);
      }
    }

    // Find removals (keys in old but not in new)
    for (final key in oldObj.keys) {
      if (!newObj.containsKey(key)) {
        final currentPath = path.isEmpty ? key : '$path.$key';
        removals[currentPath] = oldObj[key];
        pathsWithDifferences.add(currentPath);
      }
    }

    // Compare values for keys that exist in both
    for (final key in oldObj.keys) {
      if (newObj.containsKey(key)) {
        final currentPath = path.isEmpty ? key : '$path.$key';

        if (oldObj[key] is Map<String, dynamic> &&
            newObj[key] is Map<String, dynamic>) {
          // Recursively compare nested objects
          _compareObjects(
            oldObj[key] as Map<String, dynamic>,
            newObj[key] as Map<String, dynamic>,
            currentPath,
            additions,
            removals,
            changes,
            pathsWithDifferences,
          );
        } else if (oldObj[key] is List && newObj[key] is List) {
          // Compare lists
          final oldList = oldObj[key] as List;
          final newList = newObj[key] as List;

          if (!_areListsEqual(oldList, newList)) {
            changes[currentPath] = {
              'old': oldList,
              'new': newList,
            };
            pathsWithDifferences.add(currentPath);
          }
        } else if (oldObj[key] != newObj[key]) {
          // Simple value change
          changes[currentPath] = {
            'old': oldObj[key],
            'new': newObj[key],
          };
          pathsWithDifferences.add(currentPath);
        }
      }
    }
  }

  static bool _areListsEqual(List list1, List list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      if (list1[i] is Map && list2[i] is Map) {
        final map1 = Map<String, dynamic>.from(list1[i] as Map);
        final map2 = Map<String, dynamic>.from(list2[i] as Map);

        final additions = <String, dynamic>{};
        final removals = <String, dynamic>{};
        final changes = <String, dynamic>{};
        final paths = <String>[];

        _compareObjects(map1, map2, '', additions, removals, changes, paths);
        if (paths.isNotEmpty) return false;
      } else if (list1[i] != list2[i]) {
        return false;
      }
    }

    return true;
  }
}
