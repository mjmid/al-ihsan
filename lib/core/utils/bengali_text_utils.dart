import 'dart:core';

/// Utility functions for handling Bengali text normalization,
/// specifically for unifying subject categories that differ only in vowel signs (কার).
class BengaliTextUtils {
  /// Regular expression matching all Bengali vowel signs (কার), virama (হসন্ত),
  /// candrabindu, anusvara, and visarga.
  /// া (া), ি (ি), ী (ী), ু (ু), ূ (ূ),
  /// ৃ (ৃ), ৄ (ৄ), ে (ে), ৈ (ৈ), ো (ো), ৌ (ৌ),
  /// ্ (্), ঁ (ঁ), ং (ং), ঃ (ঃ), ৗ (ৗ)
  static final RegExp _karAndDiacriticsRegex =
      RegExp(r'[\u09BE-\u09CC\u09CD\u0981-\u0983\u09D7]');

  /// Normalizes a Bengali subject or phrase by:
  /// 1. Lowercasing & trimming whitespace
  /// 2. Normalizing independent vowels: 'ঈ' -> 'ই', 'ঊ' -> 'উ'
  /// 3. Removing all vowel signs (কার) and diacritics
  /// 4. Collapsing redundant whitespace
  static String normalizeSubject(String? text) {
    if (text == null) return '';
    String s = text.trim().toLowerCase();
    if (s.isEmpty) return '';

    // Normalize independent vowels
    s = s.replaceAll('ঈ', 'ই').replaceAll('ঊ', 'উ');

    // Strip all kars and diacritics
    s = s.replaceAll(_karAndDiacriticsRegex, '');

    // Collapse multiple spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Returns true if two subject strings represent the same canonical subject,
  /// ignoring kar differences (e.g., 'তাফসীর' and 'তাফসির', 'হাদিস' and 'হাদীস').
  static bool isSameSubject(String? a, String? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    final normA = normalizeSubject(a);
    final normB = normalizeSubject(b);
    if (normA.isEmpty && normB.isEmpty) {
      return a.trim().toLowerCase() == b.trim().toLowerCase();
    }
    return normA == normB;
  }

  /// Aggregates a raw map of {category: count} by canonical subject.
  ///
  /// For variants that normalize to the same key (e.g. 'তাফসির': 162, 'তাফসীর': 25):
  /// - The variant with the highest individual count becomes the display name ('তাফসির').
  /// - The total count becomes the sum of all variants (187).
  /// - The returned map is sorted descending by total count, then alphabetically.
  static Map<String, int> aggregateCategoryCounts(Map<String, int> rawCounts) {
    final Map<String, _CategoryGroup> groups = {};

    for (final entry in rawCounts.entries) {
      final rawName = entry.key.trim();
      if (rawName.isEmpty) continue;
      final count = entry.value;

      final key = normalizeSubject(rawName);
      final groupKey = key.isEmpty ? rawName.toLowerCase() : key;

      if (!groups.containsKey(groupKey)) {
        groups[groupKey] = _CategoryGroup(
          displayName: rawName,
          totalCount: count,
          highestSingleCount: count,
        );
      } else {
        final existing = groups[groupKey]!;
        existing.totalCount += count;
        if (count > existing.highestSingleCount) {
          existing.highestSingleCount = count;
          existing.displayName = rawName;
        }
      }
    }

    final sortedList = groups.values.toList()
      ..sort((a, b) {
        final countComparison = b.totalCount.compareTo(a.totalCount);
        if (countComparison != 0) return countComparison;
        return a.displayName.compareTo(b.displayName);
      });

    return {
      for (final group in sortedList) group.displayName: group.totalCount,
    };
  }
}

class _CategoryGroup {
  String displayName;
  int totalCount;
  int highestSingleCount;

  _CategoryGroup({
    required this.displayName,
    required this.totalCount,
    required this.highestSingleCount,
  });
}
