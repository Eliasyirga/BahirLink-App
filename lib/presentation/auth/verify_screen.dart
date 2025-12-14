import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../services/verification_service.dart';

/// ===== Fixed White & Blue Theme =====
const Color kPrimaryBlue = Color(0xFF1E6FFF);
const Color kBackground = Color(0xFFF6F8FC);
const Color kCardWhite = Colors.white;
const Color kBorderBlue = Color(0xFFE3ECFF);
const Color kSuccess = Color(0xFF2ECC71);
const Color kError = Color(0xFFE74C3C);

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({Key? key}) : super(key: key);

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  File? idImage;
  File? selfie;

  bool loading = false;
  Map<String, dynamic>? result;

  final ImagePicker _picker = ImagePicker();
  final VerificationService _verificationService = VerificationService(
    baseUrl: 'http://10.161.148.41:5000',
  );

  /// Compress image
  Future<File> _compressImage(File file) async {
    final String targetPath = file.path.replaceFirst(
      RegExp(r'\.(jpg|jpeg|png)$'),
      '_cmp.jpg',
    );

    final XFile? compressedXFile =
        await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: 70,
        );

    if (compressedXFile == null) return file;
    return File(compressedXFile.path);
  }

  /// Pick image from camera
  Future<File?> _pickFromCamera({required CameraDevice camera}) async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: camera,
      imageQuality: 100,
    );

    if (picked == null) return null;

    return _compressImage(File(picked.path));
  }

  Future<void> pickIdImage() async {
    final file = await _pickFromCamera(camera: CameraDevice.rear);
    if (file != null) setState(() => idImage = file);
  }

  Future<void> pickSelfie() async {
    final file = await _pickFromCamera(camera: CameraDevice.front);
    if (file != null) setState(() => selfie = file);
  }

  Future<void> submitVerification() async {
    if (idImage == null || selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture both images')),
      );
      return;
    }

    setState(() {
      loading = true;
      result = null;
    });

    try {
      final response = await _verificationService.verify(
        idImage: idImage!,
        selfie: selfie!,
      );
      setState(() => result = response);
    } catch (e) {
      setState(() => result = {'success': false, 'error': e.toString()});
    } finally {
      setState(() => loading = false);
    }
  }

  /// ===== Camera Card =====
  Widget _cameraCard(
    String label,
    File? image,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 190,
        decoration: BoxDecoration(
          color: kCardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorderBlue),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: kBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: image != null
                    ? Image.file(image, fit: BoxFit.cover)
                    : Icon(icon, size: 36, color: kPrimaryBlue),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              image == null ? 'Tap to capture' : 'Captured',
              style: TextStyle(
                fontSize: 12,
                color: image == null ? Colors.grey : kSuccess,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== Status Card =====
  Widget _statusCard() {
    if (result == null) return const SizedBox.shrink();

    final bool success = result!['success'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: success ? kSuccess : kError, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(
            success ? Icons.verified_rounded : Icons.error_outline_rounded,
            size: 44,
            color: success ? kSuccess : kError,
          ),
          const SizedBox(height: 10),
          Text(
            success ? 'Verification Successful' : 'Verification Failed',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: success ? kSuccess : kError,
            ),
          ),
          if (!success) ...[
            const SizedBox(height: 10),
            Text(
              const JsonEncoder.withIndent('  ').convert(result),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  /// ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kCardWhite,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'ID Verification',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Step 2 of 3', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 6),
            const Text(
              'Verify Your Identity',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _cameraCard(
                  'Government ID',
                  idImage,
                  Icons.credit_card,
                  pickIdImage,
                ),
                _cameraCard(
                  'Live Selfie',
                  selfie,
                  Icons.camera_alt,
                  pickSelfie,
                ),
              ],
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            _statusCard(),
          ],
        ),
      ),
    );
  }
}
