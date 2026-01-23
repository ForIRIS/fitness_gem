import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import 'camera_view.dart';
import 'ai_interview_view.dart';

/// SettingsView - 설정 화면
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
  bool _showApiKey = false;

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

    _profile!.guardianPhone = _guardianController.text.isEmpty
        ? null
        : _guardianController.text;
    await UserProfile.save(_profile!);

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
                  // 프로필 정보
                  _buildSection(
                    title: AppLocalizations.of(context)!.profileInfo,
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

                  // AI 컨설팅
                  _buildSection(
                    title: AppLocalizations.of(context)!.aiConsulting,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.aiConsultingSubtitle,
                    child: _buildReinterviewButton(),
                  ),

                  const SizedBox(height: 24),

                  // 보호자 연락처
                  _buildSection(
                    title: AppLocalizations.of(context)!.guardianPhone,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.guardianPhoneDescription,
                    child: Column(
                      children: [
                        TextField(
                          controller: _guardianController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterPhone,
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
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveGuardianPhone,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                            ),
                            child: Text(AppLocalizations.of(context)!.save),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // API Key 설정
                  _buildSection(
                    title: 'Gemini API Key',
                    subtitle: AppLocalizations.of(context)!.testCamera,
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

                  // 앱 정보
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

                  // 기능 테스트
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
                        // 커리큘럼 없이 카메라 뷰 실행 (테스트 모드)
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
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
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
            icon: const Icon(Icons.refresh, size: 18),
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

    // 인터뷰 완료 시 프로필 다시 로드
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
