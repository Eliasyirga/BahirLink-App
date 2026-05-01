// import 'dart:typed_data';
// import 'dart:io' show File;
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import 'map_picker_page.dart';
// import '../../services/emergency_service.dart';
// import '../../services/kebele_service.dart';
// import 'media_picker_bottom_sheet.dart';

// class GuestEmergencyReportPage extends StatefulWidget {
//   final String emergencyTypeId;
//   final String categoryId;
//   final String emergencyTypeName;
//   final String categoryName;

//   const GuestEmergencyReportPage({
//     super.key,
//     required this.emergencyTypeId,
//     required this.categoryId,
//     required this.emergencyTypeName,
//     required this.categoryName,
//   });

//   @override
//   State<GuestEmergencyReportPage> createState() =>
//       _GuestEmergencyReportPageState();
// }

// class _GuestEmergencyReportPageState extends State<GuestEmergencyReportPage> {
//   // Text Controllers
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _subdivisionController = TextEditingController();
//   final TextEditingController _streetController = TextEditingController();

//   // Logic & State
//   // ✅ Initialized as empty list to prevent JS "Symbol(dartx.map)" error
//   List<Map<String, dynamic>> _kebeles = [];
//   String? _selectedKebeleId;
//   bool _isFetchingKebeles = true;
//   bool _isLoading = false;

//   double? _latitude;
//   double? _longitude;
//   Uint8List? _selectedMediaBytes;
//   File? _selectedFile;
//   String? _selectedFileName;

//   // Design Tokens (BahirLink Brand)
//   final Color primaryBlue = const Color(0xff0D47A1);
//   final Color accentBlue = const Color(0xff1976D2);
//   final Color scaffoldBg = const Color(0xffF8FAFD);

//   @override
//   void initState() {
//     super.initState();
//     _fetchKebeleData();
//   }

//   Future<void> _fetchKebeleData() async {
//     try {
//       final data = await KebeleService().getAllKebeles();
//       if (mounted) {
//         setState(() {
//           _kebeles = data ?? [];
//           _isFetchingKebeles = false;
//         });
//       }
//     } catch (e) {
//       debugPrint("Kebele Fetch Error: $e");
//       if (mounted) {
//         setState(() {
//           _kebeles = [];
//           _isFetchingKebeles = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _descriptionController.dispose();
//     _phoneController.dispose();
//     _subdivisionController.dispose();
//     _streetController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: scaffoldBg,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: primaryBlue,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               widget.emergencyTypeName,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             Text(
//               widget.categoryName,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white.withOpacity(0.7),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHeaderIcon(),
//                 const SizedBox(height: 32),
//                 _sectionTitle("Emergency Details"),
//                 _buildTextArea(
//                   _descriptionController,
//                   "Describe the situation...",
//                 ),
//                 const SizedBox(height: 24),

//                 _sectionTitle("Location & Contact"),
//                 _buildInputField(
//                   _phoneController,
//                   "Contact Phone",
//                   Icons.phone_android,
//                   keyboard: TextInputType.phone,
//                 ),
//                 const SizedBox(height: 16),

//                 // ✅ Drodown with safety guards
//                 _buildKebeleDropdown(),

//                 const SizedBox(height: 16),
//                 _buildInputField(
//                   _subdivisionController,
//                   "Subdivision / Village",
//                   Icons.location_city,
//                 ),
//                 const SizedBox(height: 16),
//                 _buildInputField(
//                   _streetController,
//                   "Street (Optional)",
//                   Icons.add_road,
//                 ),
//                 const SizedBox(height: 32),

//                 _sectionTitle("Attachments"),
//                 _buildLocationPicker(),
//                 const SizedBox(height: 12),
//                 _buildMediaPicker(),
//                 const SizedBox(height: 48),

//                 _buildSubmitButton(),
//                 const SizedBox(height: 60),
//               ],
//             ),
//           ),
//           if (_isLoading) _buildLoadingOverlay(),
//         ],
//       ),
//     );
//   }

//   // --- UI Components ---

//   Widget _buildHeaderIcon() => Center(
//     child: Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         shape: BoxShape.circle,
//       ),
//       child: const Icon(
//         Icons.emergency_share,
//         color: Colors.redAccent,
//         size: 40,
//       ),
//     ),
//   );

//   Widget _sectionTitle(String title) => Padding(
//     padding: const EdgeInsets.only(bottom: 12, left: 4),
//     child: Text(
//       title.toUpperCase(),
//       style: TextStyle(
//         fontSize: 11,
//         fontWeight: FontWeight.w800,
//         color: primaryBlue.withOpacity(0.6),
//         letterSpacing: 1.1,
//       ),
//     ),
//   );

//   Widget _buildKebeleDropdown() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: _inputDecoration(),
//       child: DropdownButtonFormField<String>(
//         value: _selectedKebeleId,
//         isExpanded: true,
//         hint: Text(
//           _isFetchingKebeles ? "Loading locations..." : "Select Kebele",
//         ),
//         decoration: const InputDecoration(
//           border: InputBorder.none,
//           icon: Icon(Icons.map_outlined, size: 20),
//         ),

//         // ✅ CRITICAL: Prevent .map() on null/empty via ternary
//         items: _kebeles.isEmpty
//             ? null
//             : _kebeles
//                   .map(
//                     (k) => DropdownMenuItem<String>(
//                       value: k['id']?.toString(),
//                       child: Text(k['name'] ?? "Unknown"),
//                     ),
//                   )
//                   .toList(),

//         onChanged: _isFetchingKebeles
//             ? null
//             : (val) => setState(() => _selectedKebeleId = val),
//       ),
//     );
//   }

//   Widget _buildInputField(
//     TextEditingController controller,
//     String label,
//     IconData icon, {
//     TextInputType keyboard = TextInputType.text,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       decoration: _inputDecoration(),
//       child: TextField(
//         controller: controller,
//         keyboardType: keyboard,
//         decoration: InputDecoration(
//           icon: Icon(icon, size: 20, color: accentBlue),
//           hintText: label,
//           border: InputBorder.none,
//         ),
//       ),
//     );
//   }

//   Widget _buildTextArea(TextEditingController controller, String hint) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _inputDecoration(),
//       child: TextField(
//         controller: controller,
//         maxLines: 4,
//         decoration: InputDecoration(hintText: hint, border: InputBorder.none),
//       ),
//     );
//   }

//   Widget _buildLocationPicker() {
//     bool hasLoc = _latitude != null;
//     return GestureDetector(
//       onTap: () async {
//         final res = await Navigator.push(
//           context,
//           MaterialPageRoute(builder: (_) => const MapPickerPage()),
//         );
//         if (res != null)
//           setState(() {
//             _latitude = res.latitude;
//             _longitude = res.longitude;
//           });
//       },
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: _inputDecoration(),
//         child: Row(
//           children: [
//             Icon(Icons.gps_fixed, color: hasLoc ? Colors.green : accentBlue),
//             const SizedBox(width: 12),
//             Text(
//               hasLoc ? "Location Pinned" : "Pin GPS Location",
//               style: TextStyle(color: hasLoc ? Colors.green : Colors.black87),
//             ),
//             const Spacer(),
//             if (hasLoc)
//               const Icon(Icons.check_circle, color: Colors.green, size: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMediaPicker() {
//     return GestureDetector(
//       onTap: _handleMediaSelection,
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: _inputDecoration(),
//         child: Row(
//           children: [
//             Icon(
//               Icons.camera_alt_outlined,
//               color: _selectedFileName != null ? Colors.green : accentBlue,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 _selectedFileName ?? "Upload Photo/Video",
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             if (_selectedFileName != null)
//               const Icon(Icons.check_circle, color: Colors.green, size: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSubmitButton() => SizedBox(
//     width: double.infinity,
//     height: 56,
//     child: ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         backgroundColor: primaryBlue,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         elevation: 0,
//       ),
//       onPressed: _isLoading ? null : _submitReport,
//       child: const Text(
//         "SEND EMERGENCY REPORT",
//         style: TextStyle(
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1,
//           color: Colors.white,
//         ),
//       ),
//     ),
//   );

//   BoxDecoration _inputDecoration() => BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(16),
//     boxShadow: [
//       BoxShadow(
//         color: Colors.black.withOpacity(0.03),
//         blurRadius: 10,
//         offset: const Offset(0, 4),
//       ),
//     ],
//   );

//   Widget _buildLoadingOverlay() => Container(
//     color: Colors.black26,
//     child: const Center(child: CircularProgressIndicator(color: Colors.white)),
//   );

//   // --- Actions ---

//   void _handleMediaSelection() {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) => MediaPickerBottomSheet(
//         onFileSelectedWeb: (bytes, name) => setState(() {
//           _selectedMediaBytes = bytes;
//           _selectedFileName = name;
//           _selectedFile = null;
//         }),
//         onFileSelectedMobile: (file) => setState(() {
//           _selectedFile = file;
//           _selectedFileName = file.path.split("/").last;
//           _selectedMediaBytes = null;
//         }),
//       ),
//     );
//   }

//   Future<void> _submitReport() async {
//     if (_descriptionController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _selectedKebeleId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Please fill all required fields")),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final res = await EmergencyService.createGuestEmergency(
//         contactNo: _phoneController.text,
//         kebele: _selectedKebeleId!,
//         subdivision: _subdivisionController.text,
//         street: _streetController.text,
//         description: _descriptionController.text,
//         emergencyTypeId: widget.emergencyTypeId,
//         categoryId: widget.categoryId,
//         latitude: _latitude,
//         longitude: _longitude,
//         mediaBytes: _selectedMediaBytes,
//         mediaFile: _selectedFile,
//         mediaName: _selectedFileName,
//       );

//       if (mounted) {
//         if (res['success'] == true) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Report Sent"),
//               backgroundColor: Colors.green,
//             ),
//           );
//         } else {
//           throw Exception("Failed");
//         }
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Failed to submit report")),
//         );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
// }

import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'map_picker_page.dart';
import '../../services/emergency_service.dart';
import '../../services/kebele_service.dart';
import '../../services/device_service.dart'; // ✅ ADDED
import 'media_picker_bottom_sheet.dart';

class GuestEmergencyReportPage extends StatefulWidget {
  final String emergencyTypeId;
  final String categoryId;
  final String emergencyTypeName;
  final String categoryName;

  const GuestEmergencyReportPage({
    super.key,
    required this.emergencyTypeId,
    required this.categoryId,
    required this.emergencyTypeName,
    required this.categoryName,
  });

  @override
  State<GuestEmergencyReportPage> createState() =>
      _GuestEmergencyReportPageState();
}

class _GuestEmergencyReportPageState extends State<GuestEmergencyReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _subdivisionController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  List<Map<String, dynamic>> _kebeles = [];
  String? _selectedKebeleId;
  bool _isFetchingKebeles = true;
  bool _isLoading = false;

  double? _latitude;
  double? _longitude;
  Uint8List? _selectedMediaBytes;
  File? _selectedFile;
  String? _selectedFileName;

  final Color primaryBlue = const Color(0xff0D47A1);
  final Color accentBlue = const Color(0xff1976D2);
  final Color scaffoldBg = const Color(0xffF8FAFD);

  @override
  void initState() {
    super.initState();
    _fetchKebeleData();
  }

  Future<void> _fetchKebeleData() async {
    try {
      final data = await KebeleService().getAllKebeles();
      if (mounted) {
        setState(() {
          _kebeles = data ?? [];
          _isFetchingKebeles = false;
        });
      }
    } catch (e) {
      debugPrint("Kebele Fetch Error: $e");
      if (mounted) {
        setState(() {
          _kebeles = [];
          _isFetchingKebeles = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _subdivisionController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryBlue,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.emergencyTypeName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.categoryName,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderIcon(),
                const SizedBox(height: 32),
                _sectionTitle("Emergency Details"),
                _buildTextArea(
                    _descriptionController, "Describe the situation..."),
                const SizedBox(height: 24),
                _sectionTitle("Location & Contact"),
                _buildInputField(
                  _phoneController,
                  "Contact Phone",
                  Icons.phone_android,
                  keyboard: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildKebeleDropdown(),
                const SizedBox(height: 16),
                _buildInputField(_subdivisionController,
                    "Subdivision / Village", Icons.location_city),
                const SizedBox(height: 16),
                _buildInputField(
                    _streetController, "Street (Optional)", Icons.add_road),
                const SizedBox(height: 32),
                _sectionTitle("Attachments"),
                _buildLocationPicker(),
                const SizedBox(height: 12),
                _buildMediaPicker(),
                const SizedBox(height: 48),
                _buildSubmitButton(),
                const SizedBox(height: 60),
              ],
            ),
          ),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emergency_share,
              color: Colors.redAccent, size: 40),
        ),
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: primaryBlue.withOpacity(0.6),
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _buildKebeleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputDecoration(),
      child: DropdownButtonFormField<String>(
        value: _selectedKebeleId,
        isExpanded: true,
        hint:
            Text(_isFetchingKebeles ? "Loading locations..." : "Select Kebele"),
        decoration: const InputDecoration(
          border: InputBorder.none,
          icon: Icon(Icons.map_outlined, size: 20),
        ),
        items: _kebeles.isEmpty
            ? null
            : _kebeles
                .map((k) => DropdownMenuItem<String>(
                      value: k['id']?.toString(),
                      child: Text(k['name'] ?? "Unknown"),
                    ))
                .toList(),
        onChanged: _isFetchingKebeles
            ? null
            : (val) => setState(() => _selectedKebeleId = val),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _inputDecoration(),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          icon: Icon(icon, size: 20, color: accentBlue),
          hintText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _inputDecoration(),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none),
      ),
    );
  }

  Widget _buildLocationPicker() {
    bool hasLoc = _latitude != null;
    return GestureDetector(
      onTap: () async {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MapPickerPage()),
        );
        if (res != null) {
          setState(() {
            _latitude = res.latitude;
            _longitude = res.longitude;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _inputDecoration(),
        child: Row(
          children: [
            Icon(Icons.gps_fixed, color: hasLoc ? Colors.green : accentBlue),
            const SizedBox(width: 12),
            Text(hasLoc ? "Location Pinned" : "Pin GPS Location"),
            const Spacer(),
            if (hasLoc)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
    return GestureDetector(
      onTap: _handleMediaSelection,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _inputDecoration(),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined,
                color: _selectedFileName != null ? Colors.green : accentBlue),
            const SizedBox(width: 12),
            Expanded(child: Text(_selectedFileName ?? "Upload Photo/Video")),
            if (_selectedFileName != null)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _isLoading ? null : _submitReport,
          child: const Text("SEND EMERGENCY REPORT",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );

  BoxDecoration _inputDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      );

  Widget _buildLoadingOverlay() => Container(
        color: Colors.black26,
        child: const Center(child: CircularProgressIndicator()),
      );

  void _handleMediaSelection() {
    showModalBottomSheet(
      context: context,
      builder: (_) => MediaPickerBottomSheet(
        onFileSelectedWeb: (bytes, name) => setState(() {
          _selectedMediaBytes = bytes;
          _selectedFileName = name;
        }),
        onFileSelectedMobile: (file) => setState(() {
          _selectedFile = file;
          _selectedFileName = file.path.split("/").last;
        }),
      ),
    );
  }

  Future<void> _submitReport() async {
    final deviceId = await DeviceService.getDeviceId(); // ✅ ADDED

    setState(() => _isLoading = true);

    try {
      final res = await EmergencyService.createGuestEmergency(
        contactNo: _phoneController.text,
        kebele: _selectedKebeleId!,
        subdivision: _subdivisionController.text,
        street: _streetController.text,
        description: _descriptionController.text,
        emergencyTypeId: widget.emergencyTypeId,
        categoryId: widget.categoryId,
        latitude: _latitude,
        longitude: _longitude,
        mediaBytes: _selectedMediaBytes,
        mediaFile: _selectedFile,
        mediaName: _selectedFileName,
        deviceId: deviceId, // ✅ ADDED
      );

      if (mounted && res['success'] == true) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Report Sent"), backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
