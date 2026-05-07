import '../models/prediction_result.dart';
import '../services/api_service.dart';

class PredictionRepository {
  const PredictionRepository({required ApiService apiService})
      : _api = apiService;

  final ApiService _api;

  Future<PredictionResult> predictNumeric({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String source,
  }) async {
    final json = await _api.predictNumeric(
      poids: poids,
      volume: volume,
      conductivite: conductivite,
      opacite: opacite,
      rigidite: rigidite,
      source: source,
    );
    return PredictionResult.fromJson(json);
  }

  Future<PredictionResult> predictMultimodal({
    required double poids,
    required double volume,
    required double conductivite,
    required double opacite,
    required double rigidite,
    required String source,
    required String rapport,
  }) async {
    final json = await _api.predictMultimodal(
      poids: poids,
      volume: volume,
      conductivite: conductivite,
      opacite: opacite,
      rigidite: rigidite,
      source: source,
      rapport: rapport,
    );
    return PredictionResult.fromJson(json);
  }
}
