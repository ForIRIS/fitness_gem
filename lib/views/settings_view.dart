import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/gemini_service.dart';
import 'camera_view.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API Key가 저장되었습니다.')));
    }
  }

  Future<void> _saveGuardianPhone() async {
    if (_profile == null) return;

    _profile!.guardianPhone = _guardianController.text.isEmpty
        ? null
        : _guardianController.text;
    await UserProfile.save(_profile!);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('보호자 연락처가 저장되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('설정', style: TextStyle(color: Colors.white)),
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
                    title: '프로필 정보',
                    child: Column(
                      children: [
                        _buildInfoRow('나이', _profile?.age ?? '-'),
                        _buildInfoRow(
                          '경험 수준',
                          _profile?.experienceLevel ?? '-',
                        ),
                        _buildInfoRow('목표', _profile?.goal ?? '-'),
                        _buildInfoRow('부상 이력', _profile?.injuryHistory ?? '-'),
                        _buildInfoRow('타겟 운동', _profile?.targetExercise ?? '-'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 보호자 연락처
                  _buildSection(
                    title: '보호자 연락처 (선택)',
                    subtitle: '낙상 감지 시 알림을 받을 연락처',
                    child: Column(
                      children: [
                        TextField(
                          controller: _guardianController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '전화번호 입력',
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
                            child: const Text('저장'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // API Key 설정
                  _buildSection(
                    title: 'Gemini API Key',
                    subtitle: '테스트용 API Key 변경',
                    child: Column(
                      children: [
                        TextField(
                          controller: _apiKeyController,
                          obscureText: !_showApiKey,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'API Key 입력',
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
                            child: const Text('API Key 저장'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 앱 정보
                  _buildSection(
                    title: '앱 정보',
                    child: Column(
                      children: [
                        _buildInfoRow('버전', '1.0.0'),
                        _buildInfoRow('빌드', 'Hackathon Edition'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 기능 테스트
                  _buildSection(
                    title: '기능 테스트',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      title: const Text(
                        '카메라 테스트',
                        style: TextStyle(color: Colors.white),
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
