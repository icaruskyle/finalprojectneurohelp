import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String? gender;
  bool isDarkMode = false;

  // Controller for birthday field
  final TextEditingController _birthdateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 🎨 Colors for both modes
    final Color backgroundLight1 = const Color(0xFFD1C4E9); // light purple
    final Color backgroundLight2 = const Color(0xFFB39DDB); // lavender
    final Color backgroundDark1 = const Color(0xFF1E1E2C); // deep gray-purple
    final Color backgroundDark2 = const Color(0xFF121212); // dark mode background

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

        // 🌙 Dark mode toggle button (moon/sun icon)
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: iconColor,
            ),
            onPressed: () {
              setState(() {
                isDarkMode = !isDarkMode;
              });
            },
          ),
        ],
      ),

      // 🌈 Background gradient similar to Welcome page
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

                // 🪪 PERSONAL INFO CARD
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
                          label: "Full Name",
                          icon: Icons.person_outline,
                          inputType: TextInputType.name,
                          isDarkMode: isDarkMode,
                        ),
                        _buildTextField(
                          label: "Username",
                          icon: Icons.account_circle_outlined,
                          inputType: TextInputType.text,
                          isDarkMode: isDarkMode,
                        ),
                        _buildTextField(
                          label: "Email Address",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          isDarkMode: isDarkMode,
                        ),

                        // 🎂 Birthday (Calendar Picker)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextField(
                            controller: _birthdateController,
                            readOnly: true,
                            style: TextStyle(
                                color:
                                isDarkMode ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: "Birthday",
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.white70
                                    : Colors.deepPurple,
                              ),
                              prefixIcon: Icon(
                                Icons.cake_outlined,
                                color: iconColor,
                              ),
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
                                        onSurface: Colors.white,
                                      )
                                          : const ColorScheme.light(
                                        primary: Colors.deepPurple,
                                        onSurface: Colors.black,
                                      ),
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

                        // 👩 Gender Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: gender,
                          dropdownColor: isDarkMode
                              ? const Color(0xFF2C2C2C)
                              : Colors.white,
                          decoration: InputDecoration(
                            labelText: "Gender",
                            labelStyle: TextStyle(color: textColor),
                            prefixIcon: Icon(Icons.person_2_outlined,
                                color: iconColor),
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
                            DropdownMenuItem(
                                value: "Other", child: Text("Other")),
                          ],
                          onChanged: (value) => setState(() => gender = value),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          label: "Contact Number",
                          icon: Icons.phone_outlined,
                          inputType: TextInputType.phone,
                          isDarkMode: isDarkMode,
                        ),
                        const SizedBox(height: 30),

                        // 💾 SAVE BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      "Personal information saved successfully!"),
                                  backgroundColor: isDarkMode
                                      ? Colors.purpleAccent
                                      : Colors.deepPurple,
                                ),
                              );
                            },
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

  // 🔹 Reusable textfield widget
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextInputType inputType,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        keyboardType: inputType,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          TextStyle(color: isDarkMode ? Colors.white70 : Colors.deepPurple),
          prefixIcon:
          Icon(icon, color: isDarkMode ? Colors.purpleAccent : Colors.deepPurple),
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
