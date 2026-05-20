import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../view_models/mlops_view_model.dart';
import '../widgets/drift_widgets.dart';
import '../widgets/prometheus_widgets.dart';

class DataDriftPage extends StatelessWidget {
  const DataDriftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MlopsViewModel>();
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────
            Text('MONITORING',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                    color: AppColors.inkTertiary, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text('Data drift',
                style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary)),
            const SizedBox(height: 20),

            // ── Status pill ────────────────────────────────────
            _StatusPill(vm: vm),
            const SizedBox(height: 24),

            // ── Feature Drift Card ─────────────────────────────
            _FeatureDriftCard(vm: vm),
            const SizedBox(height: 24),

            // ── API Metrics ────────────────────────────────────
            _ApiMetricsCard(vm: vm),
            const SizedBox(height: 16),

            // ── Prometheus Observability ──────────────────────
            _PrometheusCard(vm: vm),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Status Pill ─────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.vm});
  final MlopsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F3D22), Color(0xFF112E1E)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ecoGreen.withAlpha(40), width: 1),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: AppColors.ecoGreen, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vm.driftStatus, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 14,
                    fontWeight: FontWeight.w600, color: AppColors.ecoGreen)),
                Text('${vm.driftLastScan}  ·  ${vm.driftEngine}',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feature Drift Card ──────────────────────────────────────────
class _FeatureDriftCard extends StatelessWidget {
  const _FeatureDriftCard({required this.vm});
  final MlopsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('FEATURE DRIFT\n(JENSEN-SHANNON)',
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppColors.inkTertiary, letterSpacing: 0.5, height: 1.3)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mlopsBlue.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.mlopsBlue.withAlpha(80), width: 1),
                ),
                child: Text(vm.driftBadge, style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                    fontWeight: FontWeight.w600, color: AppColors.mlopsBlue)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vm.driftFeatures.map((f) => DriftBar(feature: f, threshold: vm.driftThreshold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(width: 12, height: 2, color: AppColors.errorRed),
              const SizedBox(width: 6),
              Text('threshold ${vm.driftThreshold.toStringAsFixed(2)}',
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 9, color: AppColors.errorRed)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── API Metrics Card ────────────────────────────────────────────
class _ApiMetricsCard extends StatelessWidget {
  const _ApiMetricsCard({required this.vm});
  final MlopsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API METRICS · LIVE',
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.inkTertiary, letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ApiStat(label: 'Requests', value: vm.apiMetrics.requests.toString(), unit: '', valueColor: AppColors.inkPrimary)),
            Expanded(child: ApiStat(label: 'Avg latency', value: vm.apiMetrics.avgLatency.toStringAsFixed(0), unit: 'ms', valueColor: AppColors.inkPrimary)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: ApiStat(label: 'Error rate', value: vm.apiMetrics.errorRate.toStringAsFixed(1), unit: '%',
                valueColor: vm.apiMetrics.errorRate < 5 ? AppColors.ecoGreen : AppColors.errorRed)),
            Expanded(child: ApiStat(label: 'p95 latency', value: vm.apiMetrics.p95Latency.toStringAsFixed(0), unit: 'ms',
                valueColor: vm.apiMetrics.p95Latency < 500 ? AppColors.mlopsGold : AppColors.errorRed)),
          ]),
          const SizedBox(height: 16),
          Text('Latency trend (ms)',
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary)),
          const SizedBox(height: 8),
          SizedBox(height: 40, child: LatencySparkline(data: vm.latencyTrend)),
        ],
      ),
    );
  }
}

// ── Prometheus Observability Card ───────────────────────────────
class _PrometheusCard extends StatelessWidget {
  const _PrometheusCard({required this.vm});
  final MlopsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: vm.promAvailable ? AppColors.ecoGreen.withAlpha(60) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 8, height: 8,
                decoration: BoxDecoration(
                  color: vm.promAvailable ? AppColors.ecoGreen : AppColors.inkTertiary,
                  shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(
              vm.promAvailable ? 'PROMETHEUS · CONNECTED' : 'PROMETHEUS · OFFLINE',
              style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, fontWeight: FontWeight.w600,
                  color: vm.promAvailable ? AppColors.ecoGreen : AppColors.inkTertiary, letterSpacing: 0.5),
            ),
            const Spacer(),
            if (vm.promAvailable)
              Text('⏱ ${vm.uptimeFormatted}',
                  style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 11, color: AppColors.inkSecondary)),
          ]),
          const SizedBox(height: 16),

          if (vm.promAvailable) ...[
            Row(children: [
              Expanded(child: PromStat(label: 'Total Requests', value: vm.promTotalRequests.toString(), icon: Icons.call_received_rounded)),
              const SizedBox(width: 12),
              Expanded(child: PromStat(label: 'Error Rate', value: '${vm.promErrorRate.toStringAsFixed(1)}%', icon: Icons.error_outline_rounded)),
              const SizedBox(width: 12),
              Expanded(child: PromStat(label: 'Uptime', value: vm.uptimeFormatted, icon: Icons.timer_outlined)),
            ]),
            const SizedBox(height: 20),

            Text('REQUEST RATE (req/s · last 30 min)',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            SizedBox(height: 80, child: TimeSeriesChart(series: vm.requestRateSeries, color: AppColors.ecoGreen)),
            const SizedBox(height: 20),

            Text('P95 LATENCY (ms · last 30 min)',
                style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            SizedBox(height: 80, child: TimeSeriesChart(series: vm.latencySeries, color: const Color(0xFF38BDF8))),
            const SizedBox(height: 20),

            if (vm.endpointBreakdown.isNotEmpty) ...[
              Text('TRAFFIC BY ENDPOINT',
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10, color: AppColors.inkTertiary, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              ...vm.endpointBreakdown.take(6).map((ep) {
                final name = ep['endpoint'] as String? ?? '';
                final count = (ep['count'] as num?)?.toInt() ?? 0;
                final maxCount = (vm.endpointBreakdown[0]['count'] as num?)?.toInt() ?? 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: EndpointBar(name: name, count: count, maxCount: maxCount),
                );
              }),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Start Prometheus with docker compose up to see live time-series metrics.',
                  style: TextStyle(fontFamily: AppFonts.inter, fontSize: 12, color: AppColors.inkTertiary)),
            ),
        ],
      ),
    );
  }
}
