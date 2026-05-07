/// Aggregated dashboard statistics.
/// NOTE: DashboardRepository currently returns mock data.
/// Replace with a real /stats endpoint call when available.
class ClusterPoint {
  const ClusterPoint({
    required this.x,
    required this.y,
    required this.clusterId,
  });

  final double x;
  final double y;
  final int clusterId;
}

class CategoryStat {
  const CategoryStat({required this.name, required this.count});

  final String name;
  final int count;

  double fraction(int total) => total > 0 ? count / total : 0;
}

class DashboardStats {
  const DashboardStats({
    required this.totalSamples,
    required this.categoryCount,
    required this.clusterCount,
    required this.modelAccuracy,
    required this.categoryStats,
    required this.clusterPoints,
  });

  final int totalSamples;
  final int categoryCount;
  final int clusterCount;
  final double modelAccuracy;
  final List<CategoryStat> categoryStats;
  final List<ClusterPoint> clusterPoints;

  int get totalCategoryCount =>
      categoryStats.fold(0, (sum, s) => sum + s.count);
}
