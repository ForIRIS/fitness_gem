import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FallConfirmationDialog extends StatefulWidget {
  final VoidCallback onOk;
  final VoidCallback onTimeout;

  const FallConfirmationDialog({
    super.key,
    required this.onOk,
    required this.onTimeout,
  });

  @override
  State<FallConfirmationDialog> createState() => _FallConfirmationDialogState();
}

class _FallConfirmationDialogState extends State<FallConfirmationDialog> {
  int _countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              "Are you okay?",
              style: GoogleFonts.barlowCondensed(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "We detected a possible fall.",
              style: GoogleFonts.barlow(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 20,
              ),
            ),
            const Spacer(),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Text(
                  "$_countdown",
                  style: GoogleFonts.barlowCondensed(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: ElevatedButton(
                onPressed: widget.onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red[900],
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                  minimumSize: const Size(double.infinity, 0),
                ),
                child: Text(
                  "I'm Okay",
                  style: GoogleFonts.barlow(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
