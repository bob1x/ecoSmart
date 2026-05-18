import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// "Was this correct?" row shown after a prediction.
/// Displays 4 category buttons. Tapping one triggers [onFeedback]
/// with the selected label. Shows a check animation after tap.
class FeedbackRow extends StatefulWidget {
  const FeedbackRow({
    super.key,
    required this.predictedLabel,
    required this.onFeedback,
  });

  final String predictedLabel;
  final void Function(String correctLabel) onFeedback;

  @override
  State<FeedbackRow> createState() => _FeedbackRowState();
}

class _FeedbackRowState extends State<FeedbackRow> {
  bool _submitted = false;
  String? _selectedLabel;

  void _onTap(String label) {
    if (_submitted) return;
    setState(() {
      _submitted = true;
      _selectedLabel = label;
    });
    widget.onFeedback(label);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _submitted
          ? _ConfirmationRow(
              key: const ValueKey('confirmed'),
              wasCorrect: _selectedLabel == widget.predictedLabel,
            )
          : _ButtonsRow(
              key: const ValueKey('buttons'),
              predictedLabel: widget.predictedLabel,
              onTap: _onTap,
            ),
    );
  }
}

class _ButtonsRow extends StatelessWidget {
  const _ButtonsRow({
    super.key,
    required this.predictedLabel,
    required this.onTap,
  });

  final String predictedLabel;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Résultat correct ?',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 11,
            color: AppColors.inkTertiary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ['Métal', 'Papier', 'Plastique', 'Verre'].map((cat) {
            final isPredict = cat == predictedLabel;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => onTap(cat),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: isPredict
                          ? AppColors.ecoGreenLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPredict
                            ? AppColors.ecoGreen.withAlpha(80)
                            : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: AppFonts.inter,
                        fontSize: 10,
                        fontWeight:
                            isPredict ? FontWeight.w600 : FontWeight.w400,
                        color: isPredict
                            ? AppColors.ecoGreen
                            : AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({super.key, required this.wasCorrect});
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          wasCorrect ? Icons.check_circle_rounded : Icons.info_rounded,
          color: wasCorrect ? AppColors.ecoGreen : AppColors.mlopsGold,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          wasCorrect ? 'Merci ! Prédiction confirmée.' : 'Merci ! Correction enregistrée.',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 12,
            color: wasCorrect ? AppColors.ecoGreen : AppColors.mlopsGold,
          ),
        ),
      ],
    );
  }
}
