import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/hero_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../data/models/dashboard_stats.dart';
import '../view_models/dashboard_view_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          HeroBar(
            title: 'Dashboard',
            subtitle: '7 274 échantillons · mis à jour il y a 5 min',
            backgroundColor: AppColors.forestDark,
            trailing: IconButton(
              icon: const Icon(Icons.search, color: AppColors.inkPrimary),
              onPressed: () {},
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: context.watch<DashboardViewModel>(),
              builder: (context, _) {
                final vm = context.read<DashboardViewModel>();
                if (vm.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.ecoGreen),
                  );
                }
                if (vm.error != null) {
                  return Center(
                    child: Text(
                      'Erreur: ${vm.error}',
                      style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.inkSecondary),
                    ),
                  );
                }
                final stats = vm.stats;
                if (stats == null) return const SizedBox();
                return _DashboardContent(stats: stats);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricGrid(stats: stats),
          const SizedBox(height: 16),
          const SectionLabel('Cluster view — PCA'),
          const SizedBox(height: 8),
          EcoCard(
            padding: const EdgeInsets.all(16),
            child: _ClusterScatterChart(points: stats.clusterPoints),
          ),
          const SizedBox(height: 16),
          const SectionLabel('Répartition des catégories'),
          const SizedBox(height: 8),
          EcoCard(
            padding: const EdgeInsets.all(16),
            child: _CategoryBarChart(
              stats: stats.categoryStats,
              total: stats.totalCategoryCount,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Metric Grid ────────────────────────────────────────────────
class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (label: 'Échantillons', value: stats.totalSamples.toString(), accent: AppColors.ecoGreen),
      (label: 'Catégories', value: stats.categoryCount.toString(), accent: AppColors.aiPurple),
      (label: 'Clusters', value: stats.clusterCount.toString(), accent: AppColors.mlopsGold),
      (label: 'Précision', value: '${(stats.modelAccuracy * 100).toStringAsFixed(1)}%', accent: AppColors.ecoGreen),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: metrics
          .map((m) => _MetricCard(label: m.label, value: m.value, accentColor: m.accent))
          .toList(),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.accentColor});

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.spaceGrotesk,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 11,
              color: AppColors.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cluster Scatter Chart ──────────────────────────────────────
class _ClusterScatterChart extends StatelessWidget {
  const _ClusterScatterChart({required this.points});

  final List<ClusterPoint> points;

  static const _clusterColors = [
    AppColors.ecoGreen,
    AppColors.aiPurple,
    AppColors.mlopsGold,
    AppColors.orange,
  ];

  static const _clusterLabels = [
    'Cluster 1 — Plastiques légers',
    'Cluster 2 — Métaux denses',
    'Cluster 3 — Matériaux organiques',
    'Cluster 4 — Mixte',
  ];

  @override
  Widget build(BuildContext context) {
    final allSpots = points.map((pt) {
      final color = _clusterColors[pt.clusterId % _clusterColors.length];
      return ScatterSpot(pt.x, pt.y, dotPainter: FlDotCirclePainter(color: color, radius: 5));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: allSpots,
              minX: -3, maxX: 3, minY: -3, maxY: 3,
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              scatterTouchData: ScatterTouchData(
                enabled: true,
                touchTooltipData: ScatterTouchTooltipData(
                  getTooltipColor: (_) => AppColors.surfaceLight,
                  getTooltipItems: (spot) {
                    final clusterId = points
                        .firstWhere(
                          (p) => (p.x - spot.x).abs() < 0.01 && (p.y - spot.y).abs() < 0.01,
                          orElse: () => ClusterPoint(x: 0, y: 0, clusterId: 0),
                        )
                        .clusterId;
                    return ScatterTooltipItem(
                      _clusterLabels[clusterId % _clusterLabels.length],
                      textStyle: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 11,
                        color: AppColors.inkPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(4, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: _clusterColors[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text('C${i + 1}', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ── Category Bar Chart ─────────────────────────────────────────
class _CategoryBarChart extends StatelessWidget {
  const _CategoryBarChart({required this.stats, required this.total});

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
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
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
