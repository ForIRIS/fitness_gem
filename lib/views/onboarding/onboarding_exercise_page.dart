import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class OnboardingExercisePage extends StatefulWidget {
  final TextEditingController exerciseController;

  const OnboardingExercisePage({super.key, required this.exerciseController});

  @override
  State<OnboardingExercisePage> createState() => _OnboardingExercisePageState();
}

class _OnboardingExercisePageState extends State<OnboardingExercisePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.targetExercise,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppTheme.indigoInk,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.selectExercise,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children:
                    [
                      {
                        'name': AppLocalizations.of(context)!.exerciseSquat,
                        'value': 'squat_air',
                        'icon': Icons.accessibility_new,
                      },
                      {
                        'name': AppLocalizations.of(context)!.exercisePushup,
                        'value': 'pushup_standard',
                        'icon': Icons.fitness_center,
                      },
                      {
                        'name': AppLocalizations.of(context)!.exerciseLunge,
                        'value': 'lunge_standard',
                        'icon': Icons.directions_run,
                      },
                      {
                        'name': AppLocalizations.of(context)!.exercisePlank,
                        'value': 'plank_standard',
                        'icon': Icons.view_headline,
                      },
                    ].map((exercise) {
                      final isSelected =
                          widget.exerciseController.text == exercise['value'];
                      return ChoiceChip(
                        label: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                exercise['icon'] as IconData,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(exercise['name'] as String),
                            ],
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primary,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        elevation: isSelected ? 4 : 0,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : AppTheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        onSelected: (selected) {
                          setState(
                            () => widget.exerciseController.text =
                                exercise['value'] as String,
                          );
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
