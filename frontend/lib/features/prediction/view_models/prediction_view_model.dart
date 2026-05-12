import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/prediction_result.dart';
import '../../../data/repositories/prediction_repository.dart';

class PredictionViewModel extends ChangeNotifier {
  PredictionViewModel({required PredictionRepository repository})
      : _repository = repository;

  final PredictionRepository _repository;

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

  // ── Sources ──────────────────────────────────────────────────
  static const sources = ['Usine_A', 'Usine_B', 'Centre_Tri', 'Unknown'];

  // ── Slider change handlers ───────────────────────────────────
  // Only update state + rebuild UI, do NOT auto-call API
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
