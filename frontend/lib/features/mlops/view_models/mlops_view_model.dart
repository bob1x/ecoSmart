import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../models/mlops_models.dart';

/// ViewModel for all 3 MLOps sub-screens.
/// Fetches real metrics from /mlops/metrics on init.
class MlopsViewModel extends ChangeNotifier {
  MlopsViewModel({required ApiService apiService}) : _api = apiService {
    fetchMetrics();
  }

  final ApiService _api;

  // ── Page controller for swipe navigation ─────────────────────
  final pageController = PageController();
  int _currentPage = 0;
  int get currentPage => _currentPage;

  void setPage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  // ── Loading state ───────────────────────────────────────────
  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  // ── Experiments Data ─────────────────────────────────────────
  double _bestF1 = 0.0;
  double get bestF1 => _bestF1;

  int _totalRuns = 0;
  int get totalRuns => _totalRuns;

  String _bestRunLabel = '—';
  String get bestRunLabel => _bestRunLabel;

  String get totalRunsLabel => 'loaded from API';

  List<double> _f1History = [];
  List<double> get f1History => _f1History;

  double _f1Delta = 0.0;
  double get f1Delta => _f1Delta;

  List<ExperimentRun> _runs = [];
  List<ExperimentRun> get runs => _runs;

  // ── Data Drift ───────────────────────────────────────────────
  bool _driftDetected = false;
  bool get driftDetected => _driftDetected;

  String get driftStatus => _driftDetected ? 'Drift detected' : 'No drift detected';
  String get driftLastScan => 'Live from API';
  String get driftEngine => 'Feature Importance Proxy';
  String get driftBadge => _driftDetected ? 'Warning' : 'Stable';

  List<DriftFeature> _driftFeatures = [];
  List<DriftFeature> get driftFeatures => _driftFeatures;

  double get driftThreshold => 0.05;

  ApiMetrics _apiMetrics = const ApiMetrics(requests: 0, avgLatency: 0, errorRate: 0, p95Latency: 0);
  ApiMetrics get apiMetrics => _apiMetrics;

  List<double> _latencyTrend = [];
  List<double> get latencyTrend => _latencyTrend;

  // ── Pipeline ─────────────────────────────────────────────────
  bool _allGreen = true;
  bool get allGreen => _allGreen;

  List<CiStep> _ciSteps = [];
  List<CiStep> get ciSteps => _ciSteps;

  List<String> _matrixLabels = [];
  List<String> get matrixLabels => _matrixLabels;

  List<List<ConfusionCell>> _confusionMatrix = [];
  List<List<ConfusionCell>> get confusionMatrix => _confusionMatrix;

  int _matrixTestN = 0;
  int get matrixTestN => _matrixTestN;

  String _registryModelName = '—';
  String get registryModelName => _registryModelName;

  String _registryVersion = '—';
  String get registryVersion => _registryVersion;

  String _registryStage = '—';
  String get registryStage => _registryStage;

  // ── Fetch real metrics ──────────────────────────────────────
  Future<void> fetchMetrics() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await _api.fetchMlopsMetrics();

      // ── Parse runs ──
      final rawRuns = json['runs'] as List<dynamic>? ?? [];
      _runs = rawRuns.map((r) {
        final m = r as Map<String, dynamic>;
        return ExperimentRun(
          id: m['id'] as String? ?? '',
          name: m['name'] as String? ?? '',
          algorithm: m['algorithm'] as String? ?? '',
          f1Score: (m['f1_score'] as num?)?.toDouble() ?? 0,
          status: _parseStatus(m['status'] as String? ?? 'archived'),
        );
      }).toList();
      _totalRuns = _runs.length;

      // Best F1
      final f1Scores = _runs.map((r) => r.f1Score).where((s) => s > 0).toList();
      if (f1Scores.isNotEmpty) {
        f1Scores.sort();
        _bestF1 = f1Scores.last;
        final bestRun = _runs.firstWhere((r) => r.f1Score == _bestF1);
        _bestRunLabel = '${bestRun.name} · ${bestRun.algorithm}';
        _f1History = f1Scores;
        if (f1Scores.length >= 2) {
          _f1Delta = double.parse(
            (((f1Scores.last - f1Scores.first) / f1Scores.first) * 100).toStringAsFixed(1),
          );
        }
      }

      // ── Parse drift features ──
      final rawDrift = json['drift_features'] as List<dynamic>? ?? [];
      _driftFeatures = rawDrift.map((d) {
        final m = d as Map<String, dynamic>;
        return DriftFeature(
          name: m['name'] as String? ?? '',
          jsDivergence: (m['js_divergence'] as num?)?.toDouble() ?? 0,
          color: m['color'] as int? ?? 0xFF00D47E,
        );
      }).toList();
      _driftDetected = _driftFeatures.any((f) => f.jsDivergence > driftThreshold);

      // ── Parse feedback stats ──
      final fbStats = json['feedback_stats'] as Map<String, dynamic>? ?? {};
      final fbTotal = (fbStats['total'] as num?)?.toInt() ?? 0;
      final fbAccuracy = (fbStats['accuracy'] as num?)?.toDouble() ?? 1.0;

      // ── Parse real API stats from metrics tracker ──
      final apiStatsRaw = json['api_stats'] as Map<String, dynamic>? ?? {};
      _apiMetrics = ApiMetrics(
        requests: (apiStatsRaw['total_requests'] as num?)?.toInt() ?? 0,
        avgLatency: (apiStatsRaw['avg_latency_ms'] as num?)?.toDouble() ?? 0,
        errorRate: (apiStatsRaw['error_rate_pct'] as num?)?.toDouble() ?? 0,
        p95Latency: (apiStatsRaw['p95_latency_ms'] as num?)?.toDouble() ?? 0,
      );
      final rawTrend = apiStatsRaw['latency_trend'] as List<dynamic>? ?? [];
      _latencyTrend = rawTrend.map((e) => (e as num).toDouble()).toList();
      if (_latencyTrend.isEmpty) _latencyTrend = [0];

      // ── Parse registry ──
      final reg = json['registry'] as Map<String, dynamic>? ?? {};
      _registryModelName = reg['model_name'] as String? ?? 'waste-classifier';
      _registryVersion = reg['version'] as String? ?? 'v200';
      _registryStage = reg['stage'] as String? ?? 'Production';

      // ── Build confusion matrix from categories ──
      final cats = (reg['categories'] as List<dynamic>?)?.cast<String>() ?? ['Pla.', 'Métal', 'Verre', 'Papier'];
      _matrixLabels = cats.map((c) => c.length > 5 ? '${c.substring(0, 4)}.' : c).toList();
      _matrixTestN = fbTotal > 0 ? fbTotal : 0;

      // Use feedback confusion data if available, else generate from accuracy
      final cmRaw = json['confusion_matrix'] as Map<String, dynamic>? ?? {};
      if (cmRaw.isNotEmpty) {
        _confusionMatrix = _buildMatrixFromFeedback(cats, cmRaw);
      } else {
        _confusionMatrix = _buildDefaultMatrix(cats, fbAccuracy);
      }

      // ── CI steps from real backend health checks ──
      final rawCi = json['ci_steps'] as List<dynamic>? ?? [];
      if (rawCi.isNotEmpty) {
        _ciSteps = rawCi.map((s) {
          final m = s as Map<String, dynamic>;
          return CiStep(
            name: m['name'] as String? ?? '',
            detail: m['detail'] as String? ?? '',
            passed: m['passed'] as bool? ?? false,
          );
        }).toList();
      } else {
        _ciSteps = [CiStep(name: 'API', detail: 'no data', passed: false)];
      }
      _allGreen = _ciSteps.every((s) => s.passed);
    } catch (e) {
      _error = e.toString();
      _setFallbackData();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  RunStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'champion':
        return RunStatus.champion;
      case 'staging':
        return RunStatus.staging;
      default:
        return RunStatus.archived;
    }
  }

  List<List<ConfusionCell>> _buildMatrixFromFeedback(
    List<String> cats,
    Map<String, dynamic> cmRaw,
  ) {
    final n = cats.length;
    final matrix = List.generate(n, (_) => List.generate(n, (_) => 0));

    for (final entry in cmRaw.entries) {
      final pred = entry.key;
      final predIdx = cats.indexOf(pred);
      if (predIdx < 0) continue;
      final corrects = entry.value as Map<String, dynamic>;
      for (final ce in corrects.entries) {
        final correctIdx = cats.indexOf(ce.key);
        if (correctIdx < 0) continue;
        matrix[predIdx][correctIdx] += (ce.value as num).toInt();
      }
    }

    return List.generate(n, (i) =>
      List.generate(n, (j) =>
        ConfusionCell(value: matrix[i][j], isHighlight: i == j)));
  }

  List<List<ConfusionCell>> _buildDefaultMatrix(List<String> cats, double accuracy) {
    final n = cats.length;
    final diag = (accuracy * 100).round();
    final off = ((1 - accuracy) * 100 / (n - 1)).round();
    return List.generate(n, (i) =>
      List.generate(n, (j) =>
        ConfusionCell(value: i == j ? diag : off, isHighlight: i == j)));
  }

  void _setFallbackData() {
    _bestF1 = 0.913;
    _totalRuns = 4;
    _bestRunLabel = 'multimodal · run #4';
    _f1History = [0.85, 0.88, 0.91, 0.913];
    _f1Delta = 6.2;
    _runs = const [
      ExperimentRun(id: 'R1', name: 'RandomForest', algorithm: 'RF · default', f1Score: 0.995, status: RunStatus.champion),
      ExperimentRun(id: 'R2', name: 'NLP TF-IDF', algorithm: 'LogisticRegression', f1Score: 0.881, status: RunStatus.staging),
      ExperimentRun(id: 'R3', name: 'Multimodal', algorithm: 'LinearSVC', f1Score: 0.913, status: RunStatus.champion),
    ];
    _driftFeatures = const [
      DriftFeature(name: 'Poids', jsDivergence: 0.016, color: 0xFF00D47E),
      DriftFeature(name: 'Volume', jsDivergence: 0.029, color: 0xFF00D47E),
      DriftFeature(name: 'Conduct.', jsDivergence: 0.011, color: 0xFF38BDF8),
      DriftFeature(name: 'Opacité', jsDivergence: 0.047, color: 0xFFFB923C),
      DriftFeature(name: 'Rigidité', jsDivergence: 0.020, color: 0xFF38BDF8),
    ];
    _apiMetrics = const ApiMetrics(requests: 0, avgLatency: 142, errorRate: 0, p95Latency: 389);
    _latencyTrend = [120, 140, 135, 150, 142, 138, 145];
    _matrixLabels = ['Métal', 'Papier', 'Pla.', 'Verre'];
    _matrixTestN = 428;
    _confusionMatrix = _buildDefaultMatrix(['Métal', 'Papier', 'Plastique', 'Verre'], 0.95);
    _ciSteps = const [
      CiStep(name: 'models', detail: 'offline', passed: false),
      CiStep(name: 'features', detail: '—', passed: false),
    ];
    _allGreen = false;
    _registryModelName = 'waste-classifier';
    _registryVersion = 'v200';
    _registryStage = 'Offline';
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
