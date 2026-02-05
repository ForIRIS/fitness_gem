import 'package:flutter/material.dart';

import '../../services/emergency_flow_manager.dart';
import 'amber_mode_content.dart';
import 'red_mode_content.dart';

/// Overlay widget that displays the appropriate emergency UI based on state.
/// Listens to EmergencyFlowManager and renders Amber or Red content.
class EmergencyFlowOverlay extends StatelessWidget {
  final EmergencyFlowManager manager;

  const EmergencyFlowOverlay({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, child) {
        final state = manager.state;

        if (state == EmergencyFlowState.inactive) {
          return const SizedBox.shrink();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state == EmergencyFlowState.amber
              ? AmberModeContent(
                  key: const ValueKey('amber'),
                  onDismiss: manager.userDismissed,
                )
              : RedModeContent(
                  key: const ValueKey('red'),
                  onCancel: manager.cancelEmergency,
                  onSOS: manager.callSOS,
                ),
        );
      },
    );
  }
}
