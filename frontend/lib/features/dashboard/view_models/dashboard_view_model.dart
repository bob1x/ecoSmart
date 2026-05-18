import 'package:flutter/foundation.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required DashboardRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService;

  final DashboardRepository _repository;
  final ApiService _apiService;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Live feedback stats ──────────────────────────────────────
  int _totalFeedback = 0;
  int get totalFeedback => _totalFeedback;

  int _corrections = 0;
  int get corrections => _corrections;

  double _accuracyRate = 1.0;
  double get accuracyRate => _accuracyRate;

  bool _feedbackLoaded = false;
  bool get feedbackLoaded => _feedbackLoaded;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.fetchStats();
      // Also load live feedback stats from the API
      await _loadFeedbackStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFeedbackStats() async {
    try {
      final json = await _apiService.fetchFeedbackStats();
      _totalFeedback = (json['total_feedback'] as num).toInt();
      _corrections = (json['corrections'] as num).toInt();
      _accuracyRate = (json['accuracy_rate'] as num).toDouble();
      _feedbackLoaded = true;
    } catch (_) {
      // Backend might not be running — just use defaults
      _feedbackLoaded = false;
    }
  }
}
