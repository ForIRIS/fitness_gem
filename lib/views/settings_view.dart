import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (_completeGuardianPhone != null) {
        _profile!.guardianPhone = _completeGuardianPhone;
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
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
                                AppLocalizations.of(
                                  context,
                                )!.experienceLevelShort,
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
                              });
                            },
                            activeColor: const Color(0xFF5E35B1),
                          ),
                          child: _fallDetectionEnabled
                              ? Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    IntlPhoneField(
                                      controller: _guardianController,
                                      dropdownIconPosition:
                                          IconPosition.trailing,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(
                                          context,
                                        )!.guardianPhone,
                                        labelStyle: GoogleFonts.barlow(
                                          color: Colors.black54,
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.withOpacity(
                                          0.05,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF5E35B1),
                                          ),
                                        ),
                                      ),
                                      initialCountryCode:
                                          Localizations.localeOf(
                                            context,
                                          ).countryCode ??
                                          'KR',
                                      style: GoogleFonts.barlow(
                                        color: Colors.black87,
                                      ),
                                      dropdownTextStyle: GoogleFonts.barlow(
                                        color: Colors.black87,
                                      ),
                                      dropdownIcon: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black54,
                                      ),
                                      onChanged: (phone) {
                                        _completeGuardianPhone =
                                            phone.completeNumber;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _saveGuardianPhone,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1A237E,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
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
                          title: AppLocalizations.of(
                            context,
                          )!.geminiApiKeyTitle,
                          subtitle: AppLocalizations.of(
                            context,
                          )!.apiKeyDialogDescription,
                          child: Column(
                            children: [
                              TextField(
                                controller: _apiKeyController,
                                obscureText: !_showApiKey,
                                style: GoogleFonts.barlow(
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(
                                    context,
                                  )!.enterApiKey,
                                  hintStyle: GoogleFonts.barlow(
                                    color: Colors.black38,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.black.withOpacity(0.1),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF5E35B1),
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showApiKey
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.black54,
                                    ),
                                    onPressed: () {
                                      setState(
                                        () => _showApiKey = !_showApiKey,
                                      );
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
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
                                  builder: (context) =>
                                      const CameraView(curriculum: null),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
          ),
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
            color: Colors.black.withOpacity(0.05),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // Amber tint
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
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
                  _profile!.interviewSummary!,
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
            onPressed: canReinterview ? _startReinterview : null,
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
                borderRadius: BorderRadius.circular(12),
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
