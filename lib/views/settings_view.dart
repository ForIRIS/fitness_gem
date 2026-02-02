import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user_profile.dart';
import '../presentation/viewmodels/home_viewmodel.dart';
import '../../core/di/injection.dart';
import '../../domain/usecases/ai/get_api_key_usecase.dart';
import '../../domain/usecases/ai/set_api_key_usecase.dart';
import 'camera_view.dart';
import 'ai_interview_view.dart';
import 'settings/edit_profile_view.dart';

/// SettingsView - Settings Screen
class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();
  String? _completeGuardianPhone;
  bool _showApiKey = false;
  bool _fallDetectionEnabled = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    // Auto-load data if missing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(homeViewModelProvider);
      if (viewModel.userProfile == null && !viewModel.isLoading) {
        viewModel.loadData();
      }
    });
  }

  Future<void> _loadApiKey() async {
    final getApiKey = getIt<GetApiKeyUseCase>();
    final result = await getApiKey.execute();
    result.fold(
      (failure) => debugPrint('Error loading API key: ${failure.message}'),
      (apiKey) {
        if (mounted) {
          setState(() {
            _apiKeyController.text = apiKey;
          });
        }
      },
    );
  }

  void _initializeFromProfile(UserProfile profile) {
    if (!_isInitialized) {
      _guardianController.text = profile.guardianPhone ?? '';
      _fallDetectionEnabled = profile.fallDetectionEnabled;
      _isInitialized = true;
    }
  }

  Future<void> _saveApiKey() async {
    final setApiKey = getIt<SetApiKeyUseCase>();
    final result = await setApiKey.execute(_apiKeyController.text);

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save API key: ${failure.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.apiKeySaved)),
          );
        }
      },
    );
  }

  Future<void> _saveGuardianPhone(UserProfile profile) async {
    // Create updated profile using copyWith (immutable)
    final updatedProfile = profile.copyWith(
      fallDetectionEnabled: _fallDetectionEnabled,
      guardianPhone: _fallDetectionEnabled ? _completeGuardianPhone : null,
      updatedAt: DateTime.now(),
    );

    // Update ViewModel state
    ref.read(homeViewModelProvider).updateUserProfile(updatedProfile);

    // Note: Profile persistence handled by ViewModel
    // TODO: Implement persistence in ViewModel
    debugPrint('Guardian phone updated: ${updatedProfile.guardianPhone}');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.guardianSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(homeViewModelProvider);
    final profile = viewModel.userProfile;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple/pink
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: GoogleFonts.barlowCondensed(
            color: const Color(0xFF1A237E),
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE1BEE7), // Lighter Purple
                    Color(0xFFF3E5F5), // Base
                    Color(0xFFE3F2FD), // Light Blue tint
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Builder(
              builder: (context) {
                // Return Error/Retry view if profile missing and not loading
                if (profile == null && !viewModel.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.failedToLoadProfile,
                          style: GoogleFonts.barlow(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(homeViewModelProvider).loadData(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(AppLocalizations.of(context)!.retry),
                        ),
                      ],
                    ),
                  );
                }

                // Show loader if actually loading
                if (viewModel.isLoading || profile == null) {
                  // If profile is null but isLoading is true, showing loader is correct
                  return const Center(child: CircularProgressIndicator());
                }

                _initializeFromProfile(profile);
                return _buildContent(profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Info
          _buildSection(
            title: AppLocalizations.of(context)!.profileInfo,
            trailing: IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF5E35B1),
                size: 22,
              ),
              onPressed: () async {
                final result = await Navigator.push<UserProfile>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileView(profile: profile),
                  ),
                );
                if (result != null) {
                  // Update ViewModel with edited profile
                  ref.read(homeViewModelProvider).updateUserProfile(result);
                  debugPrint('Profile updated: ${result.nickname}');
                }
              },
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  AppLocalizations.of(context)!.age,
                  profile.age.toString(),
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.experienceLevelShort,
                  profile.fitnessLevel,
                ),
                _buildInfoRow(AppLocalizations.of(context)!.goal, profile.goal),
                _buildInfoRow(
                  AppLocalizations.of(context)!.injuryHistory,
                  profile.healthConditions,
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.targetExercise,
                  profile.targetExercise,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // AI Consulting
          _buildSection(
            title: AppLocalizations.of(context)!.aiConsulting,
            subtitle: AppLocalizations.of(context)!.aiConsultingSubtitle,
            child: _buildReinterviewButton(profile),
          ),

          const SizedBox(height: 24),

          // Guardian Contact
          _buildSection(
            title: AppLocalizations.of(context)!.guardianPhone,
            subtitle: AppLocalizations.of(context)!.guardianPhoneDescription,
            trailing: Switch(
              value: _fallDetectionEnabled,
              onChanged: (val) {
                setState(() {
                  _fallDetectionEnabled = val;
                });
              },
              activeThumbColor: const Color(0xFF5E35B1),
            ),
            child: _fallDetectionEnabled
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      IntlPhoneField(
                        controller: _guardianController,
                        dropdownIconPosition: IconPosition.trailing,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          )!.guardianPhone,
                          labelStyle: GoogleFonts.barlow(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFF5E35B1),
                            ),
                          ),
                        ),
                        initialCountryCode:
                            Localizations.localeOf(context).countryCode ?? 'KR',
                        style: GoogleFonts.barlow(color: Colors.black87),
                        dropdownTextStyle: GoogleFonts.barlow(
                          color: Colors.black87,
                        ),
                        dropdownIcon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.black54,
                        ),
                        onChanged: (phone) {
                          _completeGuardianPhone = phone.completeNumber;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _saveGuardianPhone(profile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.save,
                            style: GoogleFonts.barlow(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(
                                context,
                              )!.guardianStorageNotice,
                              style: GoogleFonts.barlow(
                                color: Colors.green[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          // API Key Settings
          _buildSection(
            title: AppLocalizations.of(context)!.geminiApiKeyTitle,
            subtitle: AppLocalizations.of(context)!.apiKeyDialogDescription,
            child: Column(
              children: [
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_showApiKey,
                  style: GoogleFonts.barlow(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.enterApiKey,
                    hintStyle: GoogleFonts.barlow(color: Colors.black38),
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(
                        color: Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: Color(0xFF5E35B1)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showApiKey ? Icons.visibility_off : Icons.visibility,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        setState(() => _showApiKey = !_showApiKey);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5E35B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.saveApiKey,
                      style: GoogleFonts.barlow(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // App Info
          _buildSection(
            title: AppLocalizations.of(context)!.appVersion,
            child: Column(
              children: [
                _buildInfoRow(
                  AppLocalizations.of(context)!.appVersion,
                  '1.0.0',
                ),
                _buildInfoRow(
                  AppLocalizations.of(context)!.appBuild,
                  AppLocalizations.of(context)!.hackathonEdition,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Feature Tests
          _buildSection(
            title: AppLocalizations.of(context)!.testCamera,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF1A237E),
                  size: 20,
                ),
              ),
              title: Text(
                AppLocalizations.of(context)!.testCamera,
                style: GoogleFonts.barlow(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black26,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraView(curriculum: null),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.barlowCondensed(
                        color: const Color(0xFF1A237E),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.barlow(
                          color: Colors.black45,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildReinterviewButton(UserProfile profile) {
    final canReinterview = profile.canReinterview;
    final daysRemaining = profile.daysUntilReinterview;
    final hasInterview = profile.interviewSummary != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasInterview && profile.interviewSummary != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Amber tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.aiConsultResult,
                      style: GoogleFonts.barlow(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profile.interviewSummary!,
                  style: GoogleFonts.barlow(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canReinterview ? () => _startReinterview(profile) : null,
            icon: Icon(
              Icons.refresh,
              color: canReinterview ? Colors.white : Colors.black26,
            ),
            label: Text(
              canReinterview
                  ? AppLocalizations.of(context)!.reconsult
                  : AppLocalizations.of(
                      context,
                    )!.daysUntilReconsult(daysRemaining),
              style: GoogleFonts.barlow(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canReinterview
                  ? const Color(0xFFFF8F00) // Deep Orange/Amber
                  : Colors.grey[200],
              foregroundColor: canReinterview ? Colors.white : Colors.black38,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: canReinterview ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        if (!canReinterview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.weeklyLimitMessage,
              style: GoogleFonts.barlow(
                color: Colors.black45,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Future<void> _startReinterview(UserProfile profile) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AIInterviewView(userProfile: profile, isFromOnboarding: false),
      ),
    );

    // Profile will be updated by AIInterviewView through provider
    if (result == true && mounted) {
      // Reload data to fetch any new curriculum
      ref.read(homeViewModelProvider).loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.consultationUpdated),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.barlow(color: Colors.black54, fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.barlow(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _guardianController.dispose();
    super.dispose();
  }
}
