import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class OnboardingBodyStatsPage extends StatefulWidget {
  final double height;
  final ValueChanged<double> onHeightChanged;
  final double weight;
  final ValueChanged<double> onWeightChanged;

  const OnboardingBodyStatsPage({
    super.key,
    required this.height,
    required this.onHeightChanged,
    required this.weight,
    required this.onWeightChanged,
  });

  @override
  State<OnboardingBodyStatsPage> createState() =>
      _OnboardingBodyStatsPageState();
}

class _OnboardingBodyStatsPageState extends State<OnboardingBodyStatsPage> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.height > 0 ? widget.height.toInt().toString() : '',
    );
    _weightController = TextEditingController(
      text: widget.weight > 0 ? widget.weight.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateHeight(double val) {
    widget.onHeightChanged(val);
    _heightController.text = val.toInt().toString();
  }

  void _updateWeight(double val) {
    widget.onWeightChanged(val);
    _weightController.text = val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Safety clamp for sliders
    final sliderHeight = widget.height.clamp(100.0, 250.0);
    final sliderWeight = widget.weight.clamp(30.0, 200.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.bodyStatsTitle,
            style: GoogleFonts.outfit(
              color: AppTheme.indigoInk,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bodyStatsDesc,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),

          // Height Section
          _buildStatSection(
            label: l10n.height,
            unit: l10n.unitCm,
            value: widget.height,
            sliderValue: sliderHeight,
            min: 100,
            max: 250,
            divisions: 150,
            controller: _heightController,
            onChanged: _updateHeight,
            icon: Icons.height,
          ),

          const SizedBox(height: 48),

          // Weight Section
          _buildStatSection(
            label: l10n.weight,
            unit: l10n.unitKg,
            value: widget.weight,
            sliderValue: sliderWeight,
            min: 30,
            max: 200,
            divisions: 170,
            controller: _weightController,
            onChanged: _updateWeight,
            icon: Icons.monitor_weight_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection({
    required String label,
    required String unit,
    required double value,
    required double sliderValue,
    required double min,
    required double max,
    required int divisions,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.end,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (text) {
                        final val = double.tryParse(text);
                        if (val != null) {
                          onChanged(val);
                        }
                      },
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: AppTheme.primary.withValues(alpha: 0.2),
              thumbColor: AppTheme.primary,
              overlayColor: AppTheme.primary.withValues(alpha: 0.2),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: sliderValue,
              min: min,
              max: max,
              divisions: divisions,
              label: sliderValue.round().toString(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
