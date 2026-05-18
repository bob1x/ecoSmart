import 'dart:math' as math;
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
            subtitle: '9 986 échantillons · classification en temps réel',
            backgroundColor: AppColors.forestDark,
            icon: Icons.dashboard_rounded,
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

// ────────────────────────────────────────────────────────────────
// Dashboard Content
// ────────────────────────────────────────────────────────────────
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Animated Metric Cards ──
          _AnimatedMetricRow(stats: stats),
          const SizedBox(height: 20),

          // ── Live Feedback Section ──
          if (vm.feedbackLoaded) ...[
            const SectionLabel('Retours utilisateurs'),
            const SizedBox(height: 8),
            _FeedbackStatsCard(
              totalFeedback: vm.totalFeedback,
              corrections: vm.corrections,
              accuracyRate: vm.accuracyRate,
            ),
            const SizedBox(height: 20),
          ],

          // ── Donut Chart ──
          const SectionLabel('Répartition par catégorie'),
          const SizedBox(height: 8),
          EcoCard(
            glowColor: AppColors.ecoGreen,
            padding: const EdgeInsets.all(20),
            child: _CategoryDonutChart(
              stats: stats.categoryStats,
              total: stats.totalCategoryCount,
            ),
          ),
          const SizedBox(height: 20),

          // ── Model Performance Radar ──
          const SectionLabel('Performance des modèles'),
          const SizedBox(height: 8),
          _ModelPerformanceCard(),
          const SizedBox(height: 20),

          // ── Cluster Scatter ──
          const SectionLabel('Cluster view — PCA'),
          const SizedBox(height: 8),
          EcoCard(
            glowColor: AppColors.aiPurple,
            padding: const EdgeInsets.all(16),
            child: _ClusterScatterChart(points: stats.clusterPoints),
          ),
          const SizedBox(height: 20),

          // ── Category Bar Chart ──
          const SectionLabel('Distribution détaillée'),
          const SizedBox(height: 8),
          EcoCard(
            padding: const EdgeInsets.all(16),
            child: _CategoryBarChart(
              stats: stats.categoryStats,
              total: stats.totalCategoryCount,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Animated Metric Row
// ────────────────────────────────────────────────────────────────
class _AnimatedMetricRow extends StatelessWidget {
  const _AnimatedMetricRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData('Échantillons', stats.totalSamples.toDouble(), '', AppColors.ecoGreen, Icons.analytics_outlined),
      _MetricData('Catégories', stats.categoryCount.toDouble(), '', AppColors.aiPurple, Icons.category_outlined),
      _MetricData('Clusters', stats.clusterCount.toDouble(), '', AppColors.mlopsGold, Icons.hub_outlined),
      _MetricData('Précision', stats.modelAccuracy * 100, '%', AppColors.ecoGreen, Icons.speed_outlined),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: metrics.map((m) => _GlassMetricCard(data: m)).toList(),
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.suffix, this.color, this.icon);
  final String label;
  final double value;
  final String suffix;
  final Color color;
  final IconData icon;
}

class _GlassMetricCard extends StatelessWidget {
  const _GlassMetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: data.value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) {
        final display = data.suffix == '%'
            ? '${animValue.toStringAsFixed(1)}${data.suffix}'
            : '${animValue.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}${data.suffix}';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.color.withAlpha(18),
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: data.color.withAlpha(30)),
            boxShadow: [
              BoxShadow(
                color: data.color.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: data.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(data.icon, size: 14, color: data.color),
                  ),
                  const Spacer(),
                  // Sparkline dots
                  _MiniSparkline(color: data.color),
                ],
              ),
              const Spacer(),
              Text(
                display,
                style: TextStyle(
                  fontFamily: AppFonts.spaceGrotesk,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                data.label,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  color: AppColors.inkTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tiny sparkline decoration for metric cards
class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(color.value);
    final points = List.generate(6, (_) => rng.nextDouble());
    return CustomPaint(
      size: const Size(40, 16),
      painter: _SparkPainter(points: points, color: color),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - points[i] * size.height * 0.8;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => false;
}

// ────────────────────────────────────────────────────────────────
// Donut Chart
// ────────────────────────────────────────────────────────────────
class _CategoryDonutChart extends StatelessWidget {
  const _CategoryDonutChart({required this.stats, required this.total});
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
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[e.key],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stat.name,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 12,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${stat.count}',
                        style: TextStyle(
                          fontFamily: AppFonts.spaceGrotesk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                      ),
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

// ────────────────────────────────────────────────────────────────
// Model Performance Card — horizontal bar chart
// ────────────────────────────────────────────────────────────────
class _ModelPerformanceCard extends StatelessWidget {
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
                    Text(
                      m.$1,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 11,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: m.$2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => Text(
                        '${(v * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontFamily: AppFonts.spaceGrotesk,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: m.$3,
                        ),
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
                              gradient: LinearGradient(
                                colors: [m.$3.withAlpha(180), m.$3],
                              ),
                              borderRadius: BorderRadius.circular(99),
                              boxShadow: [
                                BoxShadow(
                                  color: m.$3.withAlpha(40),
                                  blurRadius: 6,
                                ),
                              ],
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

// ────────────────────────────────────────────────────────────────
// Feedback Stats Card
// ────────────────────────────────────────────────────────────────
class _FeedbackStatsCard extends StatelessWidget {
  const _FeedbackStatsCard({
    required this.totalFeedback,
    required this.corrections,
    required this.accuracyRate,
  });

  final int totalFeedback;
  final int corrections;
  final double accuracyRate;

  @override
  Widget build(BuildContext context) {
    final accuracyPct = (accuracyRate * 100).toStringAsFixed(1);
    final confirmed = totalFeedback - corrections;
    final accuracyColor = accuracyRate >= 0.8
        ? AppColors.ecoGreen
        : accuracyRate >= 0.5
            ? AppColors.mlopsGold
            : AppColors.errorRed;

    return EcoCard(
      glowColor: accuracyColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accuracyColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.people_outline, size: 14, color: accuracyColor),
              ),
              const SizedBox(width: 10),
              Text(
                '$totalFeedback retours collectés',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeedbackMetric(
                  label: 'Précision réelle',
                  value: '$accuracyPct%',
                  color: accuracyColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeedbackMetric(
                  label: 'Confirmés',
                  value: '$confirmed',
                  color: AppColors.ecoGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeedbackMetric(
                  label: 'Corrections',
                  value: '$corrections',
                  color: corrections > 0 ? AppColors.mlopsGold : AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedbackMetric extends StatelessWidget {
  const _FeedbackMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 600),
          builder: (_, v, __) => Opacity(
            opacity: v,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.spaceGrotesk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 10,
            color: AppColors.inkTertiary,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Cluster Scatter Chart
// ────────────────────────────────────────────────────────────────
class _ClusterScatterChart extends StatelessWidget {
  const _ClusterScatterChart({required this.points});
  final List<ClusterPoint> points;

  static const _clusterColors = [
    AppColors.ecoGreen,
    AppColors.aiPurple,
    AppColors.mlopsGold,
    AppColors.orange,
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
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.white10,
                  strokeWidth: 0.5,
                ),
                getDrawingVerticalLine: (_) => FlLine(
                  color: AppColors.white10,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: List.generate(4, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _clusterColors[i],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cluster ${i + 1}',
                  style: TextStyle(
                    fontFamily: AppFonts.inter,
                    fontSize: 11,
                    color: AppColors.inkTertiary,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────
// Category Bar Chart
// ────────────────────────────────────────────────────────────────
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
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: value,
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color.withAlpha(150), color],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(color: color.withAlpha(30), blurRadius: 4),
                              ],
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
