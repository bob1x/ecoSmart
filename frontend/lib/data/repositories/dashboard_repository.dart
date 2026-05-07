import 'dart:math' as math;
import '../models/dashboard_stats.dart';

/// DashboardRepository
///
/// NOTE: Returns rich mock data until a real /stats endpoint is added
/// to the FastAPI backend. To replace with real data:
///   1. Add GET /stats endpoint to api/main.py
///   2. Inject ApiService here and call it
///   3. Remove _generateMockStats()
class DashboardRepository {
  const DashboardRepository();

  Future<DashboardStats> fetchStats() async {
    // Simulate network latency
    await Future.delayed(const Duration(milliseconds: 600));
    return _generateMockStats();
  }

  DashboardStats _generateMockStats() {
    final rng = math.Random(42); // seeded for reproducible UI

    // Category distribution
    final categories = [
      CategoryStat(name: 'Plastique', count: 2341),
      CategoryStat(name: 'Papier', count: 1987),
      CategoryStat(name: 'Verre', count: 1203),
      CategoryStat(name: 'Métal', count: 870),
    ];

    // PCA-like cluster scatter points
    final clusterPoints = <ClusterPoint>[];
    final clusterCenters = [
      (x: 1.2, y: 0.8),
      (x: -1.5, y: 1.2),
      (x: 0.3, y: -1.8),
      (x: -0.8, y: -0.6),
    ];

    for (int c = 0; c < 4; c++) {
      final center = clusterCenters[c];
      for (int i = 0; i < 25; i++) {
        clusterPoints.add(ClusterPoint(
          x: center.x + (rng.nextDouble() - 0.5) * 1.2,
          y: center.y + (rng.nextDouble() - 0.5) * 1.2,
          clusterId: c,
        ));
      }
    }

    return DashboardStats(
      totalSamples: 7274,
      categoryCount: 4,
      clusterCount: 4,
      modelAccuracy: 0.914,
      categoryStats: categories,
      clusterPoints: clusterPoints,
    );
  }
}
