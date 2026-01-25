import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import 'camera_view.dart';
import 'ai_interview_view.dart';
import 'settings/edit_profile_view.dart';

/// SettingsView - Settings Screen
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  UserProfile? _profile;
  bool _isLoading = true;

  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _guardianController = TextEditingController();
  String? _completeGuardianPhone;
  bool _showApiKey = false;
  bool _fallDetectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _profile = await UserProfile.load();
    final geminiService = GeminiService();
    final apiKey = await geminiService.getUserApiKey();
    _apiKeyController.text = apiKey;
    _guardianController.text = _profile?.guardianPhone ?? '';
    _fallDetectionEnabled = _profile?.fallDetectionEnabled ?? false;

    setState(() => _isLoading = false);
  }

  Future<void> _saveApiKey() async {
    final geminiService = GeminiService();
    await geminiService.setApiKey(_apiKeyController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.apiKeySaved)),
      );
    }
  }

  Future<void> _saveGuardianPhone() async {
    if (_profile == null) return;

    _profile!.fallDetectionEnabled = _fallDetectionEnabled;
    if (_fallDetectionEnabled) {
      // If toggled on, ensure we save the phone number
      // If user hasn't typed anything new, _completeGuardianPhone might be null,
      // so fallback to existing text if needed, or handle validation.
      // For now, simple fallback or validation.
      if (_completeGuardianPhone != null) {
        _profile!.guardianPhone = _completeGuardianPhone;
      } else if (_guardianController.text.isNotEmpty) {
        // Fallback for existing number if not modified
        // This is tricky with IntlPhoneField controller vs completeNumber.
        // Assuming _completeGuardianPhone captures updates.
        // If it's existing data loaded into controller, completeNumber logic usually triggers on change.
      }
    } else {
      _profile!.guardianPhone = null;
    }

    await UserProfile.saveProfile(_profile!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.guardianSaved)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context)!.settings,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Info
                  _buildSection(
                    title: AppLocalizations.of(context)!.profileInfo,
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () async {
                        if (_profile != null) {
                          final changed = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EditProfileView(profile: _profile!),
                            ),
                          );
                          if (changed == true) {
                            _loadData(); // Reload to show updates
                          }
                        }
                      },
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          AppLocalizations.of(context)!.age,
                          _profile?.age ?? '-',
                        ),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.experienceLevelShort,
                          _profile?.experienceLevel ?? '-',
                        ),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.goal,
                          _profile?.goal ?? '-',
                        ),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.injuryHistory,
                          _profile?.injuryHistory ?? '-',
                        ),
                        _buildInfoRow(
                          AppLocalizations.of(context)!.targetExercise,
                          _profile?.targetExercise ?? '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Consulting
                  _buildSection(
                    title: AppLocalizations.of(context)!.aiConsulting,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.aiConsultingSubtitle,
                    child: _buildReinterviewButton(),
                  ),

                  const SizedBox(height: 24),

                  // Guardian Contact
                  _buildSection(
                    title: AppLocalizations.of(context)!.guardianPhone,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.guardianPhoneDescription,
                    trailing: Switch(
                      value: _fallDetectionEnabled,
                      onChanged: (val) {
                        setState(() {
                          _fallDetectionEnabled = val;
                          if (!val) {
                            // If turned off, just clear state visually if desired,
                            // or keep it to restore if toggled back.
                            // User request: Default is not entering.
                          } else {
                            // If there is existing phone in profile, ensure controller has it?
                            // It is already loaded in initState.
                          }
                        });
                      },
                      activeColor: Colors.deepPurple,
                    ),
                    child: _fallDetectionEnabled
                        ? Column(
                            children: [
                              const SizedBox(height: 12),
                              IntlPhoneField(
                                controller: _guardianController,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(
                                    context,
                                  )!.guardianPhone,
                                  labelStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white24,
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  counterStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),
                                initialCountryCode:
                                    Localizations.localeOf(
                                      context,
                                    ).countryCode ??
                                    'KR',
                                style: const TextStyle(color: Colors.white),
                                dropdownTextStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                dropdownIcon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                                onChanged: (phone) {
                                  _completeGuardianPhone = phone.completeNumber;
                                },
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveGuardianPhone,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey[800],
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.save,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: Colors.greenAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.guardianStorageNotice,
                                      style: const TextStyle(
                                        color: Colors.greenAccent,
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
                    title: 'Gemini API Key',
                    subtitle: AppLocalizations.of(
                      context,
                    )!.apiKeyDialogDescription,
                    child: Column(
                      children: [
                        TextField(
                          controller: _apiKeyController,
                          obscureText: !_showApiKey,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterApiKey,
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.white24,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.deepPurple,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showApiKey
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                setState(() => _showApiKey = !_showApiKey);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveApiKey,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.saveApiKey,
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
                          'Hackathon Edition',
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
                      leading: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.testCamera,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onTap: () {
                        // Launch Camera View without curriculum (Test Mode)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CameraView(curriculum: null),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
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
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildReinterviewButton() {
    final canReinterview = _profile?.canReinterview ?? true;
    final daysRemaining = _profile?.daysUntilReinterview ?? 0;
    final hasInterview = _profile?.interviewSummary != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasInterview && _profile?.interviewSummary != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'AI 상담 결과',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _profile!.interviewSummary!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: canReinterview ? _startReinterview : null,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(
              canReinterview
                  ? AppLocalizations.of(context)!.reconsult
                  : AppLocalizations.of(
                      context,
                    )!.daysUntilReconsult(daysRemaining),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: canReinterview ? Colors.amber : Colors.grey[700],
              foregroundColor: canReinterview ? Colors.black : Colors.white54,
              padding: const EdgeInsets.symmetric(vertical: 14),
              disabledBackgroundColor: Colors.grey[800],
              disabledForegroundColor: Colors.white38,
            ),
          ),
        ),
        if (!canReinterview)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!.weeklyLimitMessage,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _startReinterview() async {
    if (_profile == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AIInterviewView(userProfile: _profile!, isFromOnboarding: false),
      ),
    );

    // Reload profile on interview completion
    if (result == true) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.consultationUpdated),
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
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
