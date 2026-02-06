import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';

class OnboardingBasicInfoPage extends StatelessWidget {
  final TextEditingController nicknameController;
  final String selectedAgeRange;
  final VoidCallback onAgePickerTap;
  final String selectedGender;
  final ValueChanged<String> onGenderSelected;

  const OnboardingBasicInfoPage({
    super.key,
    required this.nicknameController,
    required this.selectedAgeRange,
    required this.onAgePickerTap,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.profileInfo ?? 'Basic Info',
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileDescription ?? 'Tell us a bit about yourself.',
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 16),
          ),
          const SizedBox(height: 32),

          // Nickname Input
          _buildInputLabel(l10n.nickname),
          const SizedBox(height: 12),
          TextField(
            controller: nicknameController,
            style: GoogleFonts.barlow(color: Colors.black87),
            decoration: _buildInputDecoration(l10n.enterNickname),
          ),
          const SizedBox(height: 32),

          // Age Range Selection
          _buildInputLabel(l10n.ageRange),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAgePickerTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedAgeRange,
                    style: GoogleFonts.barlow(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Gender Selection (Inclusive)
          _buildInputLabel(l10n.genderTitle ?? 'Gender'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildGenderChip(
                context,
                label: l10n.genderMale ?? 'Male',
                value: 'male',
                icon: Icons.male,
              ),
              _buildGenderChip(
                context,
                label: l10n.genderFemale ?? 'Female',
                value: 'female',
                icon: Icons.female,
              ),
              _buildGenderChip(
                context,
                label: l10n.genderNonBinary ?? 'Non-binary',
                value: 'non_binary',
                icon: Icons.transgender,
              ),
              _buildGenderChip(
                context,
                label: l10n.genderPreferNotToSay ?? 'Prefer not to say',
                value: 'prefer_not_to_say',
                icon: Icons.do_not_disturb,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderChip(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = selectedGender == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : const Color(0xFF5E35B1),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onGenderSelected(value);
      },
      selectedColor: const Color(0xFF5E35B1),
      backgroundColor: Colors.white,
      labelStyle: GoogleFonts.barlow(
        color: isSelected ? Colors.white : const Color(0xFF5E35B1),
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : const Color(0xFF5E35B1).withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.barlow(
        color: Colors.black54,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.barlow(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }
}
