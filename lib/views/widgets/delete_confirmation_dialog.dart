import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/l10n/app_localizations.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final String title;
  final String message;
  final String confirmKeyword;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmKeyword,
    required this.onConfirm,
  });

  @override
  State<DeleteConfirmationDialog> createState() =>
      _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isMatched = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isMatched = _controller.text.trim() == widget.confirmKeyword;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: GoogleFonts.barlowCondensed(
          fontWeight: FontWeight.bold,
          color: Colors.red[700],
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: GoogleFonts.barlow(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.typeToConfirm(widget.confirmKeyword),
            style: GoogleFonts.barlow(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.confirmKeyword,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: GoogleFonts.barlow(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _isMatched
              ? () {
                  widget.onConfirm();
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text(
            AppLocalizations.of(context)!.delete,
            style: GoogleFonts.barlow(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
