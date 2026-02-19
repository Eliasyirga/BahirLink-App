import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MediaPickerBottomSheet extends StatelessWidget {
  final Function(File file) onFileSelected;

  const MediaPickerBottomSheet({super.key, required this.onFileSelected});

  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = ImagePicker();

    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 5,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const Text(
            "Attach Media",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff0D47A1),
            ),
          ),

          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Camera
              _mediaButton(
                icon: Icons.camera_alt,
                label: "Camera",
                color: const Color(0xff1976D2),
                onTap: () async {
                  final XFile? photo = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (photo != null) {
                    onFileSelected(File(photo.path));
                    Navigator.pop(context);
                  }
                },
              ),

              // Video
              _mediaButton(
                icon: Icons.videocam,
                label: "Video",
                color: const Color(0xff0D47A1),
                onTap: () async {
                  final XFile? video = await picker.pickVideo(
                    source: ImageSource.camera,
                  );
                  if (video != null) {
                    onFileSelected(File(video.path));
                    Navigator.pop(context);
                  }
                },
              ),

              // Gallery
              _mediaButton(
                icon: Icons.photo_library,
                label: "Gallery",
                color: const Color(0xff42A5F5),
                onTap: () async {
                  final XFile? file = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (file != null) {
                    onFileSelected(File(file.path));
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mediaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(50),
            splashColor: color.withOpacity(0.2),
            highlightColor: color.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
