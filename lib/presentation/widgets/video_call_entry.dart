import 'package:flutter/material.dart';

import '../call/call_page.dart';
import '../../services/call_services.dart';

class VideoCallEntryButton extends StatelessWidget {
  final int emergencyId;

  const VideoCallEntryButton({super.key, required this.emergencyId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Video call',
      icon: const Icon(Icons.videocam_rounded),
      onPressed: () {
        final pending = CallService.I.pendingInvite;

        // Only open if this pending invite matches this case
        if (pending != null && pending.emergencyId == emergencyId) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (_) => CallPage(invite: pending),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Wait for the responder to start the video call. '
              'The call screen will open automatically when it rings.',
            ),
          ),
        );
      },
    );
  }
}
