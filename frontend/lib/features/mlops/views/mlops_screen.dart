import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../view_models/mlops_view_model.dart';
import 'experiments_page.dart';
import 'data_drift_page.dart';
import 'pipeline_page.dart';

/// Host screen for the 3 MLOps sub-pages (swipeable PageView).
class MlopsScreen extends StatelessWidget {
  const MlopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MlopsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: vm.pageController,
              onPageChanged: vm.setPage,
              children: const [
                ExperimentsPage(),
                DataDriftPage(),
                PipelinePage(),
              ],
            ),
          ),
          // ── Dot indicators ──────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final isActive = vm.currentPage == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.ecoGreen : AppColors.inkMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
