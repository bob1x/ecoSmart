import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/hero_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../data/models/dashboard_stats.dart';
import '../view_models/dashboard_view_model.dart';
import '../widgets/dashboard_metric_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_feedback_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadStats();
      // Auto-refresh every 10 seconds for live data
      _autoRefresh = Timer.periodic(
        const Duration(seconds: 10),
        (_) {
          if (mounted) {
            context.read<DashboardViewModel>().loadStats();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
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
            child: vm.isLoading && vm.stats == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.ecoGreen),
                  )
                : vm.error != null && vm.stats == null
                    ? Center(
                        child: Text(
                          'Erreur: ${vm.error}',
                          style: TextStyle(fontFamily: AppFonts.inter, color: AppColors.inkSecondary),
                        ),
                      )
                    : _DashboardContent(stats: vm.stats!),
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
    final vm = context.watch<DashboardViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Animated Metric Cards ──
          AnimatedMetricRow(stats: stats),
          const SizedBox(height: 20),

          // ── Live Feedback Section ──
          if (vm.feedbackLoaded) ...[
            const SectionLabel('Retours utilisateurs'),
            const SizedBox(height: 8),
            FeedbackStatsCard(
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
            child: CategoryDonutChart(
              stats: stats.categoryStats,
              total: stats.totalCategoryCount,
            ),
          ),
          const SizedBox(height: 20),

          // ── Model Performance ──
          const SectionLabel('Performance des modèles'),
          const SizedBox(height: 8),
          const ModelPerformanceCard(),
          const SizedBox(height: 20),

          // ── Cluster Scatter ──
          const SectionLabel('Cluster view — PCA'),
          const SizedBox(height: 8),
          EcoCard(
            glowColor: AppColors.aiPurple,
            padding: const EdgeInsets.all(16),
            child: ClusterScatterChart(points: stats.clusterPoints),
          ),
          const SizedBox(height: 20),

          // ── Category Bar Chart ──
          const SectionLabel('Distribution détaillée'),
          const SizedBox(height: 8),
          EcoCard(
            padding: const EdgeInsets.all(16),
            child: CategoryBarChart(
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
