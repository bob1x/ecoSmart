import 'package:flutter/material.dart';
import '../models/mlops_models.dart';

/// ViewModel for all 3 MLOps sub-screens.
/// Provides hardcoded mock data matching the design screenshots exactly.
class MlopsViewModel extends ChangeNotifier {
  // ── Page controller for swipe navigation ─────────────────────
  final pageController = PageController();
  int _currentPage = 0;
  int get currentPage => _currentPage;

  void setPage(int index) {
    _currentPage = index;
    notifyListeners();
  }

  // ── Experiments Data ─────────────────────────────────────────
  double get bestF1 => 0.913;
  int get totalRuns => 5;
  String get bestRunLabel => 'multimodal · run #5';
  String get totalRunsLabel => 'logged to registry';

  List<double> get f1History => [0.90, 0.91, 0.87, 0.93, 0.913];
  double get f1Delta => 6.2;

  List<ExperimentRun> get runs => const [
        ExperimentRun(
          id: 'R5',
          name: 'Multimodal',
          algorithm: 'XGBoost · hstack',
          f1Score: 0.913,
          status: RunStatus.champion,
        ),
        ExperimentRun(
          id: 'R4',
          name: 'NLP TF-IDF',
          algorithm: 'LinearSVC · bigrams',
          f1Score: 0.881,
          status: RunStatus.staging,
        ),
        ExperimentRun(
          id: 'R3',
          name: 'NLP W2Vec',
          algorithm: 'Word2Vec · mean pool',
          f1Score: 0.862,
          status: RunStatus.archived,
        ),
        ExperimentRun(
          id: 'R2',
          name: 'RandomForest',
          algorithm: 'RandomForest · default',
          f1Score: 0.851,
          status: RunStatus.archived,
        ),
      ];

  // ── Data Drift ───────────────────────────────────────────────
  bool get driftDetected => false;
  String get driftStatus => 'No drift detected';
  String get driftLastScan => 'Last scan 2 min ago';
  String get driftEngine => 'Evidently AI';
  String get driftBadge => 'Stable';

  List<DriftFeature> get driftFeatures => const [
        DriftFeature(name: 'Poids', jsDivergence: 0.016, color: 0xFF22C55E),
        DriftFeature(name: 'Volume', jsDivergence: 0.029, color: 0xFF22C55E),
        DriftFeature(name: 'Conduct.', jsDivergence: 0.011, color: 0xFF0EA5E9),
        DriftFeature(name: 'Opacité', jsDivergence: 0.047, color: 0xFFF97316),
        DriftFeature(name: 'Rigidité', jsDivergence: 0.020, color: 0xFF0EA5E9),
      ];

  double get driftThreshold => 0.05;

  ApiMetrics get apiMetrics => const ApiMetrics(
        requests: 1284,
        avgLatency: 142,
        errorRate: 0.3,
        p95Latency: 389,
      );

  List<double> get latencyTrend => [120, 140, 135, 150, 142, 138, 145];

  // ── Pipeline ─────────────────────────────────────────────────
  bool get allGreen => true;

  List<CiStep> get ciSteps => const [
        CiStep(name: 'lint', detail: 'black · flake8 · isort  8s', passed: true),
        CiStep(name: 'test', detail: 'cov 78%  44s', passed: true),
        CiStep(name: 'flutter', detail: 'analyze · test  31s', passed: true),
        CiStep(name: 'docker', detail: 'build · push  2m4s', passed: true),
      ];

  // Confusion matrix (4x4): Plastique, Métal, Verre, Carton
  List<String> get matrixLabels => const ['Pla.', 'Métal', 'Verre', 'Cart.'];

  List<List<ConfusionCell>> get confusionMatrix => const [
        [
          ConfusionCell(value: 96, isHighlight: true),
          ConfusionCell(value: 3, isHighlight: false),
          ConfusionCell(value: 2, isHighlight: false),
          ConfusionCell(value: 1, isHighlight: false),
        ],
        [
          ConfusionCell(value: 2, isHighlight: false),
          ConfusionCell(value: 97, isHighlight: true),
          ConfusionCell(value: 1, isHighlight: false),
          ConfusionCell(value: 0, isHighlight: false),
        ],
        [
          ConfusionCell(value: 2, isHighlight: false),
          ConfusionCell(value: 1, isHighlight: false),
          ConfusionCell(value: 89, isHighlight: true),
          ConfusionCell(value: 5, isHighlight: false),
        ],
        [
          ConfusionCell(value: 1, isHighlight: false),
          ConfusionCell(value: 0, isHighlight: false),
          ConfusionCell(value: 4, isHighlight: false),
          ConfusionCell(value: 92, isHighlight: true),
        ],
      ];

  int get matrixTestN => 428;

  String get registryModelName => 'waste-classifier';
  String get registryVersion => 'v3';
  String get registryStage => 'Production';

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
