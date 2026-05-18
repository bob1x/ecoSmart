import 'package:flutter/foundation.dart';
import '../../../data/models/nlp_result.dart';
import '../../../data/repositories/nlp_repository.dart';
import '../../../data/services/api_service.dart';

class NlpViewModel extends ChangeNotifier {
  NlpViewModel({
    required NlpRepository repository,
    required ApiService apiService,
  })  : _repository = repository,
        _apiService = apiService {
    _loadHistory();
  }

  final NlpRepository _repository;
  final ApiService _apiService;

  String rapportText = '';
  NlpResult? _result;
  NlpResult? get result => _result;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<NlpHistoryItem> _history = [];
  List<NlpHistoryItem> get history => List.unmodifiable(_history);

  bool _feedbackSubmitted = false;
  bool get feedbackSubmitted => _feedbackSubmitted;

  bool get canAnalyse => rapportText.trim().length >= 10;

  /// Called from the TextField's onChanged.
  /// We intentionally do NOT call notifyListeners() here to avoid
  /// rebuilding the widget tree on every keystroke (which kills the
  /// TextField's internal state on web, causing one-char-per-line).
  void onRapportChanged(String text) {
    rapportText = text;
    // No notifyListeners() — the TextField manages its own display.
    // The "canAnalyse" state is read reactively when the button builds.
  }

  Future<void> analyse() async {
    if (!canAnalyse) return;

    _isLoading = true;
    _error = null;
    _feedbackSubmitted = false;
    notifyListeners();

    try {
      _result = await _repository.analyse(rapportText.trim());
      _loadHistory();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> deleteHistoryItem(NlpHistoryItem item) async {
    await _repository.deleteHistoryItem(item);
    _loadHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    _loadHistory();
    notifyListeners();
  }

  void _loadHistory() {
    _history = _repository.getHistory();
  }
}
