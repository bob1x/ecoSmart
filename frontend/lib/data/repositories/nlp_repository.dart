import 'package:hive_flutter/hive_flutter.dart';
import '../models/nlp_result.dart';
import '../services/api_service.dart';

const _kNlpBoxName = 'nlp_history';

class NlpRepository {
  NlpRepository({required ApiService apiService}) : _api = apiService;

  final ApiService _api;

  Box<NlpHistoryItem>? _box;

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(NlpHistoryItemAdapter());
    }
    _box = await Hive.openBox<NlpHistoryItem>(_kNlpBoxName);
  }

  Future<NlpResult> analyse(String rapport) async {
    final json = await _api.predictText(rapport);
    final result = NlpResult.fromJson(json);

    // Extract top keywords client-side (simple frequency)
    final keywords = _extractKeywords(rapport, topN: 5);

    // Persist to Hive
    final box = _box;
    if (box != null) {
      final item = NlpHistoryItem(
        rapport: rapport,
        categorie: result.categorie,
        confidence: result.confidence,
        timestamp: DateTime.now(),
        keywords: keywords,
      );
      await box.add(item);
      // Keep only last 20 entries
      if (box.length > 20) {
        await box.deleteAt(0);
      }
    }

    return NlpResult(
      categorie: result.categorie,
      confidence: result.confidence,
      keywords: keywords,
    );
  }

  List<NlpHistoryItem> getHistory() {
    final box = _box;
    if (box == null) return [];
    final items = box.values.toList();
    return items.reversed.toList(); // most recent first
  }

  Future<void> deleteHistoryItem(NlpHistoryItem item) async {
    await item.delete();
  }

  Future<void> clearHistory() async {
    await _box?.clear();
  }

  List<String> _extractKeywords(String text, {int topN = 5}) {
    final stopwords = {
      'le', 'la', 'les', 'de', 'du', 'des', 'un', 'une', 'et', 'en',
      'à', 'au', 'aux', 'est', 'son', 'sa', 'ses', 'que', 'qui', 'dans',
      'sur', 'par', 'pour', 'avec', 'lot', 'l', 'd', 'qu', 'ce',
      'the', 'an', 'in', 'of', 'to', 'and', 'is', 'it', 'at', 'a',
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp("[^\\w\\s']"), ' ')
        .split(RegExp('\\s+'))
        .where((w) => w.length > 3 && !stopwords.contains(w))
        .toList();

    final freq = <String, int>{};
    for (final w in words) {
      freq[w] = (freq[w] ?? 0) + 1;
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(topN).map((e) => e.key).toList();
  }
}
