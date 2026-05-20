// Data models for the MLOps dashboard screens.

class ExperimentRun {
  const ExperimentRun({
    required this.id,
    required this.name,
    required this.algorithm,
    required this.f1Score,
    required this.status,
  });

  final String id;
  final String name;
  final String algorithm;
  final double f1Score;
  final RunStatus status;
}

enum RunStatus { champion, staging, archived }

class DriftFeature {
  const DriftFeature({
    required this.name,
    required this.jsDivergence,
    required this.color,
  });

  final String name;
  final double jsDivergence;
  final int color; // stored as int for const
}

class ApiMetrics {
  const ApiMetrics({
    required this.requests,
    required this.avgLatency,
    required this.errorRate,
    required this.p95Latency,
  });

  final int requests;
  final double avgLatency;
  final double errorRate;
  final double p95Latency;
}

class CiStep {
  const CiStep({
    required this.name,
    required this.detail,
    required this.passed,
  });

  final String name;
  final String detail;
  final bool passed;
}

class ConfusionCell {
  const ConfusionCell({required this.value, required this.isHighlight});

  final int value;
  final bool isHighlight;
}
