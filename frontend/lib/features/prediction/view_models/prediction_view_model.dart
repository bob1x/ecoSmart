import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/prediction_result.dart';
import '../../../data/repositories/prediction_repository.dart';
import '../../../data/services/api_service.dart';

class PredictionViewModel extends ChangeNotifier {
  PredictionViewModel({
    required PredictionRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService;

  final PredictionRepository _repository;
  final ApiService _apiService;

  // ── Slider state ────────────────────────────────────────────
  double poids = 47.0;
  double volume = 65.0;
  double conductivite = 0.0;
  double opacite = 0.5;
  double rigidite = 3.0;
  String selectedSource = 'Usine_A';
  bool multimodalEnabled = false;
  String rapportText = '';

  // ── Result state ─────────────────────────────────────────────
  PredictionResult? _result;
  PredictionResult? get result => _result;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Feedback state ───────────────────────────────────────────
  bool _feedbackSubmitted = false;
  bool get feedbackSubmitted => _feedbackSubmitted;

  // ── Sources ──────────────────────────────────────────────────
  static const sources = ['Usine_A', 'Usine_B', 'Centre_Tri', 'Unknown'];

  // ── Slider change handlers ───────────────────────────────────
  void onPoidsChanged(double v) {
    poids = v;
    notifyListeners();
  }

  void onVolumeChanged(double v) {
    volume = v;
    notifyListeners();
  }

  void onConductiviteChanged(double v) {
    conductivite = v;
    notifyListeners();
  }

  void onOpaciteChanged(double v) {
    opacite = v;
    notifyListeners();
  }

  void onRigiditeChanged(double v) {
    rigidite = v;
    notifyListeners();
  }

  void onSourceChanged(String src) {
    selectedSource = src;
    notifyListeners();
  }

  void onMultimodalToggled(bool value) {
    multimodalEnabled = value;
    notifyListeners();
  }

  void onRapportChanged(String text) {
    rapportText = text;
    // No notifyListeners() — prevents TextField rebuild on web
  }

  // ── Prediction — only called when user presses the button ──
  Future<void> predict() async {
    _isLoading = true;
    _error = null;
    _feedbackSubmitted = false;
    _contributions = null;
    notifyListeners();

    try {
      if (multimodalEnabled && rapportText.trim().isNotEmpty) {
        _result = await _repository.predictMultimodal(
          poids: poids,
          volume: volume,
          conductivite: conductivite,
          opacite: opacite,
          rigidite: rigidite,
          source: selectedSource,
          rapport: rapportText,
        );
      } else {
        _result = await _repository.predictNumeric(
          poids: poids,
          volume: volume,
          conductivite: conductivite,
          opacite: opacite,
          rigidite: rigidite,
          source: selectedSource,
        );
      }
      // Auto-fetch explanation after successful prediction
      _fetchExplain();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── SHAP Explain ───────────────────────────────────────────
  List<Map<String, dynamic>>? _contributions;
  List<Map<String, dynamic>>? get contributions => _contributions;

  Future<void> _fetchExplain() async {
    try {
      final json = await _apiService.explainPrediction(
        poids: poids,
        volume: volume,
        conductivite: conductivite,
        opacite: opacite,
        rigidite: rigidite,
        source: selectedSource,
      );
      final raw = json['contributions'] as List<dynamic>?;
      if (raw != null) {
        _contributions = raw.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (_) {
      // Non-critical — don't block the prediction flow
    }
  }

  // ── Feedback ────────────────────────────────────────────────
  Future<void> submitFeedback(String correctLabel) async {
    if (_result == null || _feedbackSubmitted) return;
    try {
      await _apiService.submitFeedback(
        predictedLabel: _result!.categorie,
        correctLabel: correctLabel,
      );
      _feedbackSubmitted = true;
      notifyListeners();
    } catch (_) {
      // Silently fail — don't interrupt UX for feedback
    }
  }
}
