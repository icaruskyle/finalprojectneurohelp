import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';


class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String? gender;

  // Controllers for text fields
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _fullNameController.text = data['fullName'] ?? '';
          _birthdateController.text = data['birthday'] ?? '';
          _contactController.text = data['contact'] ?? '';
          gender = data['gender'];
        });
      } else {
        final query = await _firestore
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();
        if (query.docs.isNotEmpty) {
          final data = query.docs.first.data();
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';

            _birthdateController.text = data['birthday'] ?? '';
            _contactController.text = data['contact'] ?? '';
            gender = data['gender'];
          });
        }
      }
    }
  }


  void _showNotification(String message) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: Colors.deepPurple,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
  }

  // Save user info to Firestore
  void _saveUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _fullNameController.text.trim(),
          'birthday': _birthdateController.text.trim(),
          'contact': _contactController.text.trim(),
          'gender': gender,
        });
      } else {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': _fullNameController.text.trim(),

          'birthday': _birthdateController.text.trim(),
          'contact': _contactController.text.trim(),
          'gender': gender,
          'email': user.email,
        });
      }

      _showNotification("✅ Personal information saved successfully!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeNotifier>(context).isDarkMode;

    final Color backgroundLight1 = const Color(0xFFD1C4E9);
    final Color backgroundLight2 = const Color(0xFFB39DDB);
    final Color backgroundDark1 = const Color(0xFF1E1E2C);
    final Color backgroundDark2 = const Color(0xFF121212);


    final Color textColor = isDarkMode ? Colors.white : Colors.deepPurple;
    final Color cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color iconColor = isDarkMode ? Colors.purpleAccent : Colors.deepPurple;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Personal Information",
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: iconColor),
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
            ),
            onPressed: () {
              Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(!isDarkMode);
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [backgroundDark1, backgroundDark2]
                : [backgroundLight1, backgroundLight2],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Update your personal details here:",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  color: cardColor.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _fullNameController,
                          label: "Full Name",
                          icon: Icons.person_outline,
                          inputType: TextInputType.name,
                          isDarkMode: isDarkMode,
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextField(
                            controller: _birthdateController,
                            readOnly: true,
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: "Birthday",
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.deepPurple,
                              ),
                              prefixIcon:
                              Icon(Icons.cake_outlined, color: iconColor),
                              suffixIcon: const Icon(Icons.calendar_month),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.white24
                                      : Colors.deepPurple.shade100,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: isDarkMode
                                      ? Colors.purpleAccent
                                      : Colors.deepPurple,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                builder:
                                    (BuildContext context, Widget? child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: isDarkMode
                                          ? const ColorScheme.dark(
                                          primary: Colors.deepPurple,
                                          onSurface: Colors.white)
                                          : const ColorScheme.light(
                                          primary: Colors.deepPurple,
                                          onSurface: Colors.black),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (pickedDate != null) {
                                setState(() {
                                  _birthdateController.text =
                                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                                });
                              }
                            },
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: gender,
                          dropdownColor: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: TextStyle(color: textColor),
                            prefixIcon:
                            Icon(Icons.person_2_outlined, color: iconColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: iconColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: "Male", child: Text("Male")),
                            DropdownMenuItem(
                                value: "Female", child: Text("Female")),
                            DropdownMenuItem(value: "Other", child: Text("Other")),
                          ],
                          onChanged: (value) => setState(() => gender = value),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _contactController,
                          label: "Contact Number",
                          icon: Icons.phone_outlined,
                          inputType: TextInputType.phone,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveUserInfo,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text(
                              "Save Changes",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
                              foregroundColor: Colors.white,
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType inputType,
    required bool isDarkMode,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        readOnly: readOnly,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          TextStyle(color: isDarkMode ? Colors.white70 : Colors.deepPurple),
          prefixIcon: Icon(icon,
              color: isDarkMode ? Colors.purpleAccent : Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white24 : Colors.deepPurple.shade100,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
