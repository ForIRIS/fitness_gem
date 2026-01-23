import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingPermissionsPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onShowApiKeyDialog;

  const OnboardingPermissionsPage({
    super.key,
    required this.onNext,
    required this.onShowApiKeyDialog,
  });

  @override
  State<OnboardingPermissionsPage> createState() =>
      _OnboardingPermissionsPageState();
}

class _OnboardingPermissionsPageState extends State<OnboardingPermissionsPage> {
  bool _isCameraGranted = false;
  bool _isMicGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _isCameraGranted = camera.isGranted;
        _isMicGranted = mic.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAllGranted = _isCameraGranted && _isMicGranted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Icon(
            isAllGranted ? Icons.check_circle_outline : Icons.security,
            size: 80,
            color: isAllGranted ? Colors.greenAccent : Colors.deepPurple,
          ),
          const SizedBox(height: 24),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedTitle
                : AppLocalizations.of(context)!.permissionTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedMessage
                : AppLocalizations.of(context)!.permissionMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const Spacer(),
          // 메인 버튼 - 전체 너비
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAllGranted
                  ? widget.onNext
                  : () async {
                      // 권한 요청
                      final statuses = await [
                        Permission.camera,
                        Permission.microphone,
                      ].request();

                      debugPrint('Permission statuses: $statuses');

                      await _checkPermissions();

                      if (_isCameraGranted && _isMicGranted) {
                        widget.onNext();
                      } else {
                        // 권한이 영구 거부된 경우 설정으로 이동
                        final cameraPermanentlyDenied =
                            await Permission.camera.isPermanentlyDenied;
                        final micPermanentlyDenied =
                            await Permission.microphone.isPermanentlyDenied;

                        if ((cameraPermanentlyDenied || micPermanentlyDenied) &&
                            mounted) {
                          debugPrint('Showing settings dialog...');
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.permissionRequired,
                                style: const TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.permissionDeniedMessage,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    openAppSettings();
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.openSettings,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
              icon: Icon(isAllGranted ? Icons.arrow_forward : Icons.check),
              label: Text(
                isAllGranted
                    ? AppLocalizations.of(context)!.next
                    : AppLocalizations.of(context)!.grantPermission,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllGranted
                    ? Colors.green
                    : Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (!isAllGranted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onNext,
                child: Text(
                  AppLocalizations.of(context)!.skip,
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),
          ],

          const Spacer(),

          TextButton.icon(
            onPressed: widget.onShowApiKeyDialog,
            icon: const Icon(Icons.key, size: 16, color: Colors.white30),
            label: Text(
              AppLocalizations.of(context)!.enterApiKeyHackathon,
              style: const TextStyle(color: Colors.white30, fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
