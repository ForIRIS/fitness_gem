import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../presentation/viewmodels/home_viewmodel.dart';

class WorkoutHeader extends ConsumerWidget {
  const WorkoutHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(homeViewModelProvider);
    final curriculum = viewModel.todayCurriculum;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  l10n.todayWorkout,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                color: AppTheme.textPrimary,
              ),
            ],
          ),
          if (curriculum?.title != null)
            Text(
              curriculum!.title,
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 2),
          Text(
            curriculum?.description ?? l10n.todayProgramDescFallback,
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
