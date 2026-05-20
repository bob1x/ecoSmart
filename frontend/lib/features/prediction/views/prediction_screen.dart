import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/feature_slider.dart';
import '../../../shared/widgets/hero_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../view_models/prediction_view_model.dart';
import '../widgets/prediction_result_card.dart';
import '../widgets/prediction_shap_impact.dart';

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
                    FeatureSlider(label: 'Volume', unit: 'L', value: _vm.volume, min: 0, max: 1000, divisions: 200, onChanged: _vm.onVolumeChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Conductivité', unit: '', value: _vm.conductivite, min: 0, max: 1, divisions: 100, decimalPlaces: 2, onChanged: _vm.onConductiviteChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Opacité', unit: '', value: _vm.opacite, min: 0, max: 100, divisions: 1000, decimalPlaces: 1, onChanged: _vm.onOpaciteChanged),
                    const SizedBox(height: 12),
                    FeatureSlider(label: 'Rigidité', unit: '', value: _vm.rigidite, min: 1, max: 10, divisions: 90, onChanged: _vm.onRigiditeChanged),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionLabel('Source'),
              const SizedBox(height: 8),
              _SourceSelector(selected: _vm.selectedSource, onSelected: _vm.onSourceChanged),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SectionLabel('Mode multimodal'),
                  const Spacer(),
                  Switch(value: _vm.multimodalEnabled, onChanged: _vm.onMultimodalToggled, activeColor: AppColors.aiPurple),
                ],
              ),

              // ── Rapport field ──
              if (_vm.multimodalEnabled)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _rapportController,
                    minLines: 3, maxLines: 6,
                    style: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.inkPrimary, height: 1.55),
                    decoration: InputDecoration(
                      hintText: 'Décrivez l\'objet collecté…',
                      hintStyle: TextStyle(fontFamily: AppFonts.inter, fontSize: 13, color: AppColors.inkTertiary, fontStyle: FontStyle.italic),
                      filled: true,
                      fillColor: AppColors.aiPurpleLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.aiPurple.withAlpha(80))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.aiPurple.withAlpha(80))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.aiPurple, width: 1.5)),
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
                        const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 1.5))
                      else
                        const Icon(Icons.play_arrow_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Lancer la prédiction',
                          style: TextStyle(fontFamily: AppFonts.spaceGrotesk, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              ResultCard(result: _vm.result, isLoading: _vm.isLoading, error: _vm.error),

              // ── SHAP Waterfall ──
              if (_vm.contributions != null && _vm.contributions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionLabel('Explication du modèle'),
                const SizedBox(height: 8),
                ShapWaterfall(contributions: _vm.contributions!),
              ],

              // ── Environmental Impact ──
              if (_vm.result != null) ...[
                const SizedBox(height: 16),
                const SectionLabel('Impact environnemental'),
                const SizedBox(height: 8),
                ImpactCard(categorie: _vm.result!.categorie),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

// ── Source Selector ──────────────────────────────────────────────
class _SourceSelector extends StatelessWidget {
  const _SourceSelector({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  static const _items = [
    ('Usine_A', 'Usine A', Icons.factory_outlined),
    ('Usine_B', 'Usine B', Icons.precision_manufacturing_outlined),
    ('Centre_Tri', 'Centre Tri', Icons.recycling_outlined),
    ('Unknown', 'Inconnu', Icons.help_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: _items.map((item) {
          final isSelected = item.$1 == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(item.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [AppColors.ecoGreen.withAlpha(40), AppColors.ecoGreenDark.withAlpha(30)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: AppColors.ecoGreen.withAlpha(60)) : null,
                  boxShadow: isSelected ? [BoxShadow(color: AppColors.ecoGreen.withAlpha(15), blurRadius: 8)] : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.$3, size: 18, color: isSelected ? AppColors.ecoGreen : AppColors.inkTertiary),
                    const SizedBox(height: 4),
                    Text(item.$2, textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: AppFonts.inter, fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.ecoGreen : AppColors.inkTertiary, letterSpacing: 0.2)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
