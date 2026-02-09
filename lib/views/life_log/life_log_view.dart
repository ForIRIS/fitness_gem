import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitness_gem/theme/app_theme.dart';
import '../../presentation/controllers/life_log_controller.dart';

class LifeLogView extends StatelessWidget {
  const LifeLogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LifeLogController()..loadLogs(),
      child: const _LifeLogViewContent(),
    );
  }
}

class _LifeLogViewContent extends StatefulWidget {
  const _LifeLogViewContent();

  @override
  State<_LifeLogViewContent> createState() => _LifeLogViewContentState();
}

class _LifeLogViewContentState extends State<_LifeLogViewContent> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<LifeLogController>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Holistic Companion",
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
            onPressed: controller.loadLogs,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0EEE9), // Cloud Dancer
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: controller.isLoading && controller.logs.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : NotificationListener<OverscrollIndicatorNotification>(
                        onNotification: (overscroll) {
                          overscroll.disallowIndicator();
                          return true;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: false, // Newest at bottom for chat feel?
                          // The controller sorts by newest first usually.
                          // If we want a classic chat, we usually reverse: true and sort desc.
                          // Let's assume controller.logs is sorted DESC (newest first).
                          // So reverse: true makes newest at bottom visually? No.
                          // visual:
                          // [Item 0 (Newest)] <- Bottom
                          // [Item 1]
                          // ...
                          // To have standard chat (newest at bottom), we want:
                          // List: [Oldest, ..., Newest] and reverse: false (starts at top, scrolls down)
                          // OR List: [Newest, ..., Oldest] and reverse: true (starts at bottom, scrolls up)
                          // Let's stick to reverse: true assuming logs are Newest First.
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          itemCount: controller.logs.length,
                          itemBuilder: (context, index) {
                            final log = controller.logs[index];
                            return _buildLogItem(log, index);
                          },
                        ),
                      ),
              ),
              if (controller.isLoading)
                const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  minHeight: 2,
                ),
              _buildInputArea(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log, int index) {
    final type = log['type'];
    final data = log['data'] as Map<String, dynamic>;
    final timestamp = DateTime.parse(log['timestamp']).toLocal();
    final timeStr =
        "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}";

    // Simple Animation Hook
    // In a real premium app, we'd use flutter_animate
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildBubbleContent(type, data, timeStr),
    );
  }

  Widget _buildBubbleContent(
    String? type,
    Map<String, dynamic> data,
    String timeStr,
  ) {
    if (type == 'chat') {
      final isUser = data['role'] == 'user';
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: isUser
                ? AppTheme.primaryGradient
                : const LinearGradient(
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
              bottomRight: isUser ? Radius.zero : const Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['message'] ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  height: 1.5,
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  timeStr,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'nutrition') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['image_path'] != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Image.file(
                    File(data['image_path']),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.kiwiColada.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            size: 16,
                            color: Color(0xFF6B705C),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Meal Log • $timeStr",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['analysis'] ?? 'Analyzing...',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputArea(BuildContext context, LifeLogController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8), // Glassy impact
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: Icons.camera_alt_rounded,
            color: AppTheme.irisOrchid,
            onPressed: () => _pickImage(controller),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cloudDancer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.outfit(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: "Tell me how you feel...",
                  hintStyle: GoogleFonts.outfit(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (val) => _sendMessage(controller),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            icon: Icons.send_rounded,
            color: AppTheme.primary,
            onPressed: () => _sendMessage(controller),
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPrimary ? color : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: isPrimary ? null : Border.all(color: AppTheme.cloudDancer),
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : color, size: 20),
      ),
    );
  }

  void _sendMessage(LifeLogController controller) {
    if (_textController.text.trim().isEmpty) return;
    controller.addTextLog(_textController.text);
    _textController.clear();
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // Since we are reverse: true, 0 is the "bottom" (visually)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage(LifeLogController controller) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      if (!mounted) return;
      controller.addImageLog(File(photo.path), "Analyze this meal");
    }
  }
}
