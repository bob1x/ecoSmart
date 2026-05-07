class PredictionResult {
  const PredictionResult({
    required this.categorie,
    required this.prixRevente,
    required this.confidence,
    this.clusterId,
  });

  final String categorie;
  final double prixRevente;
  final double confidence;
  final int? clusterId;

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      categorie: json['categorie'] as String,
      prixRevente: (json['prix_revente'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
      clusterId: json['cluster_id'] as int?,
    );
  }
}
