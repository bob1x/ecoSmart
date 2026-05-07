import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/category_badge.dart';
import '../../../shared/widgets/confidence_bar.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/feature_slider.dart';
import '../../../shared/widgets/hero_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../data/models/prediction_result.dart';
import '../view_models/prediction_view_model.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          HeroBar(
            title: 'Prédiction',
            subtitle: 'Ajustez les curseurs · résultats en temps réel',
            backgroundColor: AppColors.forestDark,
          ),
          const Expanded(child: _PredictionBody()),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// StatefulWidget so we own the TextEditingController for the
// multimodal rapport field. It never gets rebuilt by the VM.
// ────────────────────────────────────────────────────────────────
class _PredictionBody extends StatefulWidget {
  const _PredictionBody();

  @override
  State<_PredictionBody> createState() => _PredictionBodyState();
}

class _PredictionBodyState extends State<_PredictionBody> {
  late final TextEditingController _rapportController;
  late final PredictionViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<PredictionViewModel>();
    _rapportController = TextEditingController(text: _vm.rapportText);
    _rapportController.addListener(_syncRapport);
  }

  void _syncRapport() {
    _vm.onRapportChanged(_rapportController.text);
  }

  @override
  void dispose() {
    _rapportController.removeListener(_syncRapport);
    _rapportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Caractéristiques'),
              const SizedBox(height: 8),
              EcoCard(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    FeatureSlider(label: 'Poids', unit: 'kg', value: _vm.poids, min: 0, max: 500, divisions: 500, onChanged: _vm.onPoidsChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Volume', unit: 'cm³', value: _vm.volume, min: 0, max: 1000, divisions: 200, onChanged: _vm.onVolumeChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Conductivité', unit: '', value: _vm.conductivite, min: 0, max: 100, divisions: 100, onChanged: _vm.onConductiviteChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Opacité', unit: '', value: _vm.opacite, min: 0, max: 100, divisions: 100, onChanged: _vm.onOpaciteChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Rigidité', unit: '', value: _vm.rigidite, min: 0, max: 100, divisions: 100, onChanged: _vm.onRigiditeChanged),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Source'),
              const SizedBox(height: 8),
              _SourceSelector(
                selected: _vm.selectedSource,
                onSelected: _vm.onSourceChanged,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SectionLabel('Mode multimodal'),
                  const Spacer(),
                  Switch(
                    value: _vm.multimodalEnabled,
                    onChanged: _vm.onMultimodalToggled,
                    activeColor: AppColors.aiPurple,
                  ),
                ],
              ),

              // ── Rapport field — uses controller from State, never rebuilt ──
              if (_vm.multimodalEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _rapportController,
                    minLines: 3,
                    maxLines: 6,
                    style: TextStyle(
                      fontFamily: AppFonts.inter,
                      fontSize: 13,
                      color: AppColors.inkPrimary,
                      height: 1.55,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Décrivez l\'objet collecté…',
                      hintStyle: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 13,
                        color: AppColors.inkTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                      filled: true,
                      fillColor: AppColors.aiPurpleLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.aiPurple.withAlpha(80)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.aiPurple.withAlpha(80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.aiPurple, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // ── Predict button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _vm.isLoading ? null : _vm.predict,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ecoGreen,
                    disabledBackgroundColor: AppColors.ecoGreen.withAlpha(100),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_vm.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 1.5),
                        )
                      else
                        const Icon(Icons.play_arrow_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lancer la prédiction',
                        style: TextStyle(
                          fontFamily: AppFonts.spaceGrotesk,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _ResultCard(result: _vm.result, isLoading: _vm.isLoading, error: _vm.error),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SourceSelector extends StatelessWidget {
  const _SourceSelector({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;
  static const _labels = {
    'Usine_A': 'Usine A',
    'Usine_B': 'Usine B',
    'Centre_Tri': 'Centre de tri',
    'Unknown': 'Inconnu',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PredictionViewModel.sources.map((src) {
          final isSelected = src == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(src),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ecoGreen : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isSelected ? AppColors.ecoGreen : AppColors.border),
                ),
                child: Text(
                  _labels[src] ?? src,
                  style: TextStyle(
                    fontFamily: AppFonts.spaceGrotesk,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? AppColors.white : AppColors.inkTertiary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.isLoading, this.error});
  final PredictionResult? result;
  final bool isLoading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: isLoading
          ? const _ShimmerResult()
          : result != null
              ? _ResultContent(result: result!)
              : _EmptyResult(error: error),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({this.error});
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultat',
          style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary),
        ),
        const SizedBox(height: 4),
        Text(
          error ?? 'Ajustez les curseurs puis lancez la prédiction',
          style: TextStyle(
            fontFamily: AppFonts.spaceGrotesk,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: error != null ? AppColors.errorRed : AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }
}

class _ResultContent extends StatelessWidget {
  const _ResultContent({required this.result});
  final PredictionResult result;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'fr_FR', symbol: '€', decimalDigits: 2);
    final catColor = AppColors.forCategory(result.categorie);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catégorie prédite', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 4),
                  Text(result.categorie, style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.inkPrimary)),
                ],
              ),
            ),
            CategoryBadge(category: result.categorie),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.white10, height: 1),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prix estimé', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 2),
                  Text('${fmt.format(result.prixRevente)}/kg', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                ],
              ),
            ),
            if (result.clusterId != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Cluster', style: TextStyle(fontFamily: AppFonts.inter, fontSize: 11, color: AppColors.inkTertiary)),
                  const SizedBox(height: 2),
                  Text('#${result.clusterId}', style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.inkPrimary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: 14),
        ConfidenceBar(confidence: result.confidence, color: catColor, label: 'Certitude', trackColor: AppColors.white10),
      ],
    );
  }
}

class _ShimmerResult extends StatefulWidget {
  const _ShimmerResult();
  @override
  State<_ShimmerResult> createState() => _ShimmerResultState();
}

class _ShimmerResultState extends State<_ShimmerResult> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double width = double.infinity, double height = 14}) => AnimatedBuilder(
        animation: _opacity,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: AppColors.white10, borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(width: 90, height: 10),
          const SizedBox(height: 8),
          _box(width: 160, height: 24),
          const SizedBox(height: 16),
          _box(height: 14),
          const SizedBox(height: 10),
          _box(height: 6),
        ],
      );
}
