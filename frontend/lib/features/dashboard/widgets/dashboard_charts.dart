import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../data/models/dashboard_stats.dart';
import '../../../shared/widgets/eco_card.dart';

/// Donut chart showing category distribution
class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.stats, required this.total});
  final List<CategoryStat> stats;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = stats.map((s) => AppColors.forCategory(s.name)).toList();

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                startDegreeOffset: -90,
                sections: stats.asMap().entries.map((e) {
                  final stat = e.value;
                  final pct = stat.fraction(total) * 100;
                  return PieChartSectionData(
                    value: stat.count.toDouble(),
                    color: colors[e.key],
                    radius: 42,
                    title: '${pct.toStringAsFixed(0)}%',
                    titleStyle: TextStyle(
                      fontFamily: AppFonts.spaceGrotesk,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stats.asMap().entries.map((e) {
                final stat = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: colors[e.key],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(stat.name,
                            style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12,
                                color: AppColors.inkSecondary)),
                      ),
                      Text('${stat.count}',
                          style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                              fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model performance horizontal bar chart
class ModelPerformanceCard extends StatelessWidget {
  const ModelPerformanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final models = [
      ('RandomForest', 0.995, AppColors.ecoGreen),
      ('NLP (LogReg)', 0.92, AppColors.aiPurple),
      ('Multimodal (SVC)', 0.94, AppColors.mlopsBlue),
      ('Régresseur', 0.89, AppColors.mlopsGold),
      ('KMeans (silhouette)', 0.78, AppColors.orange),
    ];

    return EcoCard(
      glowColor: AppColors.mlopsBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: models.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.$1,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11,
                            color: AppColors.inkSecondary)),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: m.$2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${(v * 100).toStringAsFixed(1)}%',
                        style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 12,
                            fontWeight: FontWeight.w700, color: m.$3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: m.$2),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) {
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: m.$3.withAlpha(20),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: v.clamp(0.0, 1.0),
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [m.$3.withAlpha(180), m.$3]),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [BoxShadow(color: m.$3.withAlpha(40), blurRadius: 6)],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Cluster PCA scatter chart
class ClusterScatterChart extends StatelessWidget {
  const ClusterScatterChart({super.key, required this.points});
  final List<ClusterPoint> points;

  static const _clusterColors = [
    AppColors.ecoGreen, AppColors.aiPurple, AppColors.mlopsGold, AppColors.orange,
  ];

  @override
  Widget build(BuildContext context) {
    final allSpots = points.map((pt) {
      final color = _clusterColors[pt.clusterId % _clusterColors.length];
      return ScatterSpot(pt.x, pt.y, dotPainter: FlDotCirclePainter(color: color, radius: 4));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: allSpots,
              minX: -3, maxX: 3, minY: -3, maxY: 3,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.white10, strokeWidth: 0.5),
                getDrawingVerticalLine: (_) => FlLine(color: AppColors.white10, strokeWidth: 0.5),
              ),
              titlesData: const FlTitlesData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16, runSpacing: 6,
          children: List.generate(4, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _clusterColors[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Cluster ${i + 1}',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Category distribution horizontal bar chart
class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({super.key, required this.stats, required this.total});
  final List<CategoryStat> stats;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: stats.asMap().entries.map((entry) {
        final stat = entry.value;
        final color = AppColors.forCategory(stat.name);
        final fraction = stat.fraction(total);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(stat.name,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkSecondary),
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [color.withAlpha(150), color]),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 4)],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(fraction * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 11,
                    fontWeight: FontWeight.w600, color: AppColors.inkSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
