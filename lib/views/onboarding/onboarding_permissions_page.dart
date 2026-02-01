import 'package:flutter/material.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isAllGranted
                  ? Colors.green.withOpacity(0.1)
                  : const Color(0xFF5E35B1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAllGranted ? Icons.check_circle : Icons.security,
              size: 80,
              color: isAllGranted ? Colors.green : const Color(0xFF5E35B1),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedTitle
                : AppLocalizations.of(context)!.permissionTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlowCondensed(
              color: const Color(0xFF1A237E),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isAllGranted
                ? AppLocalizations.of(context)!.permissionGrantedMessage
                : AppLocalizations.of(context)!.permissionMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.barlow(
              color: Colors.black54,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const Spacer(),
          // Main Button - Full Width
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAllGranted
                  ? widget.onNext
                  : () async {
                      // Request Permissions
                      final statuses = await [
                        Permission.camera,
                        Permission.microphone,
                      ].request();

                      debugPrint('Permission statuses: $statuses');

                      await _checkPermissions();

                      if (_isCameraGranted && _isMicGranted) {
                        widget.onNext();
                      } else {
                        // Navigate to settings if permission is permanently denied
                        final cameraPermanentlyDenied =
                            await Permission.camera.isPermanentlyDenied;
                        final micPermanentlyDenied =
                            await Permission.microphone.isPermanentlyDenied;

                        if ((cameraPermanentlyDenied || micPermanentlyDenied) &&
                            mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: Text(
                                AppLocalizations.of(
                                  context,
                                )!.permissionRequired,
                                style: GoogleFonts.barlow(
                                  color: const Color(0xFF1A237E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                AppLocalizations.of(
                                  context,
                                )!.permissionDeniedMessage,
                                style: GoogleFonts.barlow(
                                  color: Colors.black54,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    AppLocalizations.of(context)!.cancel,
                                    style: GoogleFonts.barlow(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    openAppSettings();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5E35B1),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context)!.openSettings,
                                    style: GoogleFonts.barlow(),
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
                style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAllGranted
                    ? Colors.green
                    : const Color(0xFF5E35B1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
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
                  style: GoogleFonts.barlow(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          TextButton.icon(
            onPressed: widget.onShowApiKeyDialog,
            icon: const Icon(Icons.key, size: 16, color: Colors.black26),
            label: Text(
              AppLocalizations.of(context)!.enterApiKeyHackathon,
              style: GoogleFonts.barlow(color: Colors.black26, fontSize: 12),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
