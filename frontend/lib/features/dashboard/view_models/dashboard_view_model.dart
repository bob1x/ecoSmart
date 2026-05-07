import 'package:flutter/foundation.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../data/repositories/dashboard_repository.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required DashboardRepository repository})
      : _repository = repository;

  final DashboardRepository _repository;

  DashboardStats? _stats;
  DashboardStats? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _repository.fetchStats();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
