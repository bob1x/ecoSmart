import 'package:hive/hive.dart';

part 'nlp_result.g.dart';

class NlpResult {
  const NlpResult({
    required this.categorie,
    required this.confidence,
    this.keywords = const [],
  });

  final String categorie;
  final double confidence;
  final List<String> keywords;

  factory NlpResult.fromJson(Map<String, dynamic> json) {
    return NlpResult(
      categorie: json['categorie'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

@HiveType(typeId: 0)
class NlpHistoryItem extends HiveObject {
  NlpHistoryItem({
    required this.rapport,
    required this.categorie,
    required this.confidence,
    required this.timestamp,
    this.keywords = const [],
  });

  @HiveField(0)
  final String rapport;

  @HiveField(1)
  final String categorie;

  @HiveField(2)
  final double confidence;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final List<String> keywords;

  String get snippet =>
      rapport.length > 60 ? '${rapport.substring(0, 60)}…' : rapport;

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }
}
