import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';

/// Feature slider with a tappable number that becomes an editable field.
/// Drag the slider OR tap the number to type a value manually.
class FeatureSlider extends StatefulWidget {
  const FeatureSlider({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions = 100,
    this.decimalPlaces = 1,
  });

  final String label;
  final String unit;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int divisions;
  final int decimalPlaces;

  @override
  State<FeatureSlider> createState() => _FeatureSliderState();
}

class _FeatureSliderState extends State<FeatureSlider> {
  Timer? _debounce;
  late double _localValue;
  bool _editing = false;
  late TextEditingController _textCtrl;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
    _textCtrl = TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FeatureSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_editing) {
      _localValue = widget.value;
    }
  }

  void _handleSliderChange(double value) {
    setState(() => _localValue = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
    });
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _textCtrl.text = _localValue.toStringAsFixed(widget.decimalPlaces);
      _textCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textCtrl.text.length,
      );
    });
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commitEdit();
    }
  }

  void _commitEdit() {
    final raw = double.tryParse(_textCtrl.text.replaceAll(',', '.'));
    if (raw != null) {
      final clamped = raw.clamp(widget.min, widget.max);
      setState(() {
        _localValue = clamped;
        _editing = false;
      });
      widget.onChanged(clamped);
    } else {
      setState(() => _editing = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  String get _formattedValue =>
      _localValue.toStringAsFixed(widget.decimalPlaces);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.inkSecondary,
              ),
            ),
            // Tappable value — tap to edit
            _editing
                ? SizedBox(
                    width: 80,
                    height: 28,
                    child: TextField(
                      controller: _textCtrl,
                      focusNode: _focusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,\-]')),
                      ],
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: AppFonts.spaceGrotesk,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ecoGreen,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        isDense: true,
                        suffixText: widget.unit.isNotEmpty ? ' ${widget.unit}' : null,
                        suffixStyle: TextStyle(
                          fontFamily: AppFonts.inter,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkTertiary,
                        ),
                      ),
                      onSubmitted: (_) => _commitEdit(),
                    ),
                  )
                : GestureDetector(
                    onTap: _startEditing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.ecoGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.ecoGreen.withAlpha(40)),
                      ),
                      child: Text(
                        '$_formattedValue ${widget.unit}',
                        style: TextStyle(
                          fontFamily: AppFonts.spaceGrotesk,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ecoGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackShape: _ThinTrackShape(),
          ),
          child: Slider(
            value: _localValue.clamp(widget.min, widget.max),
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: _handleSliderChange,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.min.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 10,
                color: AppColors.inkTertiary,
              ),
            ),
            Text(
              widget.max.toStringAsFixed(0),
              style: TextStyle(
                fontFamily: AppFonts.inter,
                fontSize: 10,
                color: AppColors.inkTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThinTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 3;
    final trackLeft = offset.dx;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
