import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GuardianRequestDialog extends StatelessWidget {
  final String requesterEmail;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isProcessing;

  const GuardianRequestDialog({
    super.key,
    required this.requesterEmail,
    required this.onAccept,
    required this.onDecline,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.security, color: Color(0xFF5E35B1), size: 48),
            const SizedBox(height: 16),
            Text(
              "Guardian Request",
              style: GoogleFonts.barlow(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.barlow(fontSize: 15, color: Colors.black54),
                children: [
                  const TextSpan(text: "User "),
                  TextSpan(
                    text: requesterEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const TextSpan(
                    text:
                        " wants to set you as their Safety Guardian.\n\nYou will receive emergency alerts if they detect a fall.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isProcessing)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: Text(
                        "Decline",
                        style: GoogleFonts.barlow(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Accept",
                        style: GoogleFonts.barlow(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
