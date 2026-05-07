import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../shared/widgets/category_badge.dart';
import '../../../shared/widgets/confidence_bar.dart';
import '../../../shared/widgets/eco_card.dart';
import '../../../shared/widgets/hero_bar.dart';
import '../../../shared/widgets/section_label.dart';
import '../../../data/models/nlp_result.dart';
import '../view_models/nlp_view_model.dart';

class NlpAssistantScreen extends StatelessWidget {
  const NlpAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          HeroBar(
            title: 'Assistant NLP',
            subtitle: 'Décrivez le déchet en langage naturel',
            backgroundColor: AppColors.aiPurpleDark,
          ),
          const Expanded(child: _NlpBody()),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────
// StatefulWidget: owns the TextEditingController + tracks whether
// the button should be enabled via local setState (not ViewModel).
// ────────────────────────────────────────────────────────────────
class _NlpBody extends StatefulWidget {
  const _NlpBody();

  @override
  State<_NlpBody> createState() => _NlpBodyState();
}

class _NlpBodyState extends State<_NlpBody> {
  late final TextEditingController _textController;
  late final NlpViewModel _vm;
  bool _canAnalyse = false;

  @override
  void initState() {
    super.initState();
    _vm = context.read<NlpViewModel>();
    _textController = TextEditingController(text: _vm.rapportText);
    _canAnalyse = _vm.rapportText.trim().length >= 10;
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _textController.text;
    _vm.onRapportChanged(text);
    // Update button enable state locally via setState
    final newCanAnalyse = text.trim().length >= 10;
    if (newCanAnalyse != _canAnalyse) {
      setState(() => _canAnalyse = newCanAnalyse);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Rapport de collecte'),
          const SizedBox(height: 8),

          // ── TextField — never rebuilt by ListenableBuilder ──
          TextField(
            controller: _textController,
            minLines: 4,
            maxLines: 8,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 13,
              color: AppColors.inkPrimary,
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText: 'Ex: Lot de plastique récupéré sur site industriel…',
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
          const SizedBox(height: 12),

          // ── Analyse button — uses local _canAnalyse for enable state ──
          // Wrapped in its own builder so it reacts to _vm for isLoading
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnalyseButton(
                    isLoading: _vm.isLoading,
                    canAnalyse: _canAnalyse,
                    onTap: _vm.analyse,
                  ),
                  const SizedBox(height: 16),
                  if (_vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _vm.error!,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  if (_vm.result != null)
                    _NlpResultCard(result: _vm.result!),
                  const SizedBox(height: 20),
                  const SectionLabel('Analyses récentes'),
                  const SizedBox(height: 8),
                  _HistoryList(
                    history: _vm.history,
                    onDelete: _vm.deleteHistoryItem,
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Analyse Button ─────────────────────────────────────────────
class _AnalyseButton extends StatelessWidget {
  const _AnalyseButton({
    required this.isLoading,
    required this.canAnalyse,
    required this.onTap,
  });
  final bool isLoading;
  final bool canAnalyse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (canAnalyse && !isLoading) ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.aiPurple,
          disabledBackgroundColor: AppColors.aiPurple.withAlpha(100),
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 1.5,
                ),
              )
            else
              const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 8),
            Text(
              'Analyser le rapport',
              style: TextStyle(
                fontFamily: AppFonts.spaceGrotesk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── NLP Result Card ────────────────────────────────────────────
class _NlpResultCard extends StatelessWidget {
  const _NlpResultCard({required this.result});
  final NlpResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.aiPurpleDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.aiPurple.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résultat NLP',
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 11,
              color: AppColors.inkTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.categorie,
            style: TextStyle(
              fontFamily: AppFonts.spaceGrotesk,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
          if (result.keywords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: result.keywords
                  .map((kw) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.aiPurple.withAlpha(80),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          kw,
                          style: TextStyle(
                            fontFamily: AppFonts.inter,
                            fontSize: 9,
                            color: const Color(0xFFC4B5FD),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          ConfidenceBar(
            confidence: result.confidence,
            color: AppColors.aiPurple,
            label: 'Certitude',
            trackColor: AppColors.white10,
          ),
        ],
      ),
    );
  }
}

// ── History List ───────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.history, required this.onDelete});
  final List<NlpHistoryItem> history;
  final void Function(NlpHistoryItem) onDelete;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              SvgPicture.asset(
                'assets/icons/leaf_icon.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  AppColors.inkTertiary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun historique',
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 13,
                  color: AppColors.inkTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = history[index];
        return Dismissible(
          key: Key('history_${item.key}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.white),
          ),
          onDismissed: (_) => onDelete(item),
          child: EcoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.timeAgo,
                        style: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 10,
                          color: AppColors.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CategoryBadge(category: item.categorie),
              ],
            ),
          ),
        );
      },
    );
  }
}
