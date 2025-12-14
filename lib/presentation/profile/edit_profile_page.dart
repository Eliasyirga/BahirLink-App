import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:first_app/services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;

  String? _gender;
  bool _isSaving = false;

  final List<String> _genders = ["male", "female", "other"];

  @override
  void initState() {
    super.initState();

    _firstNameController = TextEditingController(
      text: widget.userData["firstName"] ?? "",
    );
    _lastNameController = TextEditingController(
      text: widget.userData["lastName"] ?? "",
    );
    _emailController = TextEditingController(
      text: widget.userData["email"] ?? "",
    );
    _phoneController = TextEditingController(
      text: widget.userData["phone"] ?? "",
    );
    _countryController = TextEditingController(
      text: widget.userData["country"] ?? "",
    );
    _cityController = TextEditingController(
      text: widget.userData["city"] ?? "",
    );
    _addressController = TextEditingController(
      text: widget.userData["address"] ?? "",
    );

    String? rawDob = widget.userData["dateOfBirth"];
    _dobController = TextEditingController(
      text: (rawDob != null && rawDob.length >= 10)
          ? rawDob.substring(0, 10)
          : "",
    );

    // Set gender only if it's a valid value, otherwise default to null
    String? gender = widget.userData["gender"];
    _gender = _genders.contains(gender) ? gender : null;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);

    final updates = {
      "firstName": _firstNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "country": _countryController.text.trim(),
      "city": _cityController.text.trim(),
      "address": _addressController.text.trim(),
      "dateOfBirth": _dobController.text.trim(),
      "gender": _gender ?? "other",
    };

    final updatedUser = await UserService.updateProfile(updates);

    setState(() => _isSaving = false);

    if (updatedUser != null) {
      Navigator.pop(context, updatedUser);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            CircleAvatar(
              radius: 55,
              backgroundImage: const AssetImage("assets/images/avatar.jpg"),
              backgroundColor: Colors.blue.shade200,
            ),
            const SizedBox(height: 15),
            ValueListenableBuilder(
              valueListenable: _firstNameController,
              builder: (_, __, ___) {
                return Text(
                  "${_firstNameController.text} ${_lastNameController.text}"
                      .trim(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 5),
            ValueListenableBuilder(
              valueListenable: _emailController,
              builder: (_, __, ___) {
                return Text(
                  _emailController.text,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                );
              },
            ),
            const SizedBox(height: 40),

            _buildTextField(_firstNameController, "First Name", Icons.person),
            const SizedBox(height: 20),
            _buildTextField(_lastNameController, "Last Name", Icons.person),
            const SizedBox(height: 20),
            _buildTextField(_emailController, "Email", Icons.email),
            const SizedBox(height: 20),
            _buildTextField(_phoneController, "Phone", Icons.phone),
            const SizedBox(height: 20),
            _buildTextField(_countryController, "Country", Icons.flag),
            const SizedBox(height: 20),
            _buildTextField(_cityController, "City", Icons.location_city),
            const SizedBox(height: 20),
            _buildTextField(_addressController, "Address", Icons.home),
            const SizedBox(height: 20),

            InkWell(
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(_dobController.text) ?? DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );

                if (picked != null) {
                  _dobController.text = picked.toIso8601String().substring(
                    0,
                    10,
                  );
                }
              },
              child: IgnorePointer(
                child: _buildTextField(
                  _dobController,
                  "Date of Birth",
                  Icons.cake,
                ),
              ),
            ),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _genders.contains(_gender) ? _gender : null,
              hint: const Text("Select Gender"),
              decoration: InputDecoration(
                labelText: "Gender",
                border: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
                ),
              ),
              items: _genders
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(g[0].toUpperCase() + g.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _gender = val),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: Colors.blue.shade700,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blue.shade700),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
