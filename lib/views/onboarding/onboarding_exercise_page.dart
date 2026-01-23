import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class OnboardingExercisePage extends StatefulWidget {
  final TextEditingController exerciseController;

  const OnboardingExercisePage({super.key, required this.exerciseController});

  @override
  State<OnboardingExercisePage> createState() => _OnboardingExercisePageState();
}

class _OnboardingExercisePageState extends State<OnboardingExercisePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.targetExercise,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.selectExercise,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children:
                [
                  {
                    'name': AppLocalizations.of(context)!.exerciseSquat,
                    'value': 'Squat',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exercisePushup,
                    'value': 'Push-up',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exerciseLunge,
                    'value': 'Lunge',
                  },
                  {
                    'name': AppLocalizations.of(context)!.exercisePlank,
                    'value': 'Plank',
                  },
                ].map((exercise) {
                  final isSelected =
                      widget.exerciseController.text == exercise['value'];
                  return ChoiceChip(
                    label: Text(exercise['name']!),
                    selected: isSelected,
                    selectedColor: Colors.deepPurple,
                    backgroundColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    onSelected: (selected) {
                      setState(
                        () =>
                            widget.exerciseController.text = exercise['value']!,
                      );
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}
