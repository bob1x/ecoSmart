import 'dart:async';
import '../../core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _localValue = widget.value;
  }

  @override
  void didUpdateWidget(FeatureSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _localValue = widget.value;
    }
  }

  void _handleChange(double value) {
    setState(() => _localValue = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            Text(
              '$_formattedValue ${widget.unit}',
              style: TextStyle(
                fontFamily: AppFonts.spaceGrotesk,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ecoGreen,
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
            onChanged: _handleChange,
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
