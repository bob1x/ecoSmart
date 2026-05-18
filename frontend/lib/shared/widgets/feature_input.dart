import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Compact numeric input field with label and optional unit suffix.
/// Replaces the old slider-based input for a cleaner, type-friendly UX.
class FeatureInput extends StatefulWidget {
  const FeatureInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.decimalPlaces = 1,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int decimalPlaces;

  @override
  State<FeatureInput> createState() => _FeatureInputState();
}

class _FeatureInputState extends State<FeatureInput> {
  late TextEditingController _ctrl;
  late FocusNode _focus;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.value.toStringAsFixed(widget.decimalPlaces),
    );
    _focus = FocusNode()..addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _hasFocus = _focus.hasFocus);
    if (!_focus.hasFocus) _commit();
  }

  void _commit() {
    final raw = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (raw == null) {
      // Reset to current value
      _ctrl.text = widget.value.toStringAsFixed(widget.decimalPlaces);
      return;
    }
    final clamped = raw.clamp(widget.min, widget.max);
    _ctrl.text = clamped.toStringAsFixed(widget.decimalPlaces);
    widget.onChanged(clamped);
  }

  @override
  void didUpdateWidget(FeatureInput old) {
    super.didUpdateWidget(old);
    if (!_hasFocus && old.value != widget.value) {
      _ctrl.text = widget.value.toStringAsFixed(widget.decimalPlaces);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Label
        SizedBox(
          width: 100,
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.inter,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.inkSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Input field
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            decoration: BoxDecoration(
              color: _hasFocus
                  ? AppColors.ecoGreenLight
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hasFocus
                    ? AppColors.ecoGreen.withAlpha(100)
                    : AppColors.border,
              ),
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]')),
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.spaceGrotesk,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _hasFocus ? AppColors.ecoGreen : AppColors.inkPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                suffixText: widget.unit.isNotEmpty ? widget.unit : null,
                suffixStyle: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: 11,
                  color: AppColors.inkTertiary,
                ),
              ),
              onSubmitted: (_) => _commit(),
            ),
          ),
        ),
        // Range hint
        const SizedBox(width: 8),
        Text(
          '${widget.min.toStringAsFixed(0)}–${widget.max.toStringAsFixed(0)}',
          style: TextStyle(
            fontFamily: AppFonts.inter,
            fontSize: 9,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
