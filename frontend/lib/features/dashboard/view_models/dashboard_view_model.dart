import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required DashboardRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    // Auto-refresh every 15 seconds for live dashboard
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshFeedback(),
    );
  }

  final DashboardRepository _repository;
  final ApiService _apiService;
  Timer? _refreshTimer;

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
    // Only show spinner on first load, not on auto-refresh
    final isFirstLoad = _stats == null;
    if (isFirstLoad) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _stats = await _repository.fetchStats();
      // Also load live feedback stats from the API
      await _loadFeedbackStats();
      _error = null;
    } catch (e) {
      if (isFirstLoad) _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Silently refresh only the feedback section (no loading spinner)
  Future<void> _refreshFeedback() async {
    try {
      final json = await _apiService.fetchFeedbackStats();
      final newTotal = (json['total_feedback'] as num).toInt();
      final newCorrections = (json['corrections'] as num).toInt();
      final newAccuracy = (json['accuracy_rate'] as num).toDouble();

      // Only notify if data actually changed
      if (newTotal != _totalFeedback ||
          newCorrections != _corrections ||
          newAccuracy != _accuracyRate) {
        _totalFeedback = newTotal;
        _corrections = newCorrections;
        _accuracyRate = newAccuracy;
        _feedbackLoaded = true;
        notifyListeners();
      }
    } catch (_) {
      // Backend might not be running — skip silently
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

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
