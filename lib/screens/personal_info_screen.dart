import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Information"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE1BEE7)], // light blue → lavender
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Update your personal details here:",
                  style: TextStyle(fontSize: 18,
                  color: Colors.purple,
            ),
                ),
                const SizedBox(height: 20),

                // Personal Info Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Full Name
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Username
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Age
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Age",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 20),

                        // Birthday
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Birthday (MM/DD/YYYY)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.calendar_month),
                          ),
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 20),

                        // Gender
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: "Gender",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.person_2_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: "Male", child: Text("Male")),
                            DropdownMenuItem(
                                value: "Female", child: Text("Female")),
                            DropdownMenuItem(
                                value: "Other", child: Text("Other")),
                          ],
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 20),

                        // Contact Number
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Contact Number",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            prefixIcon: const Icon(Icons.contacts),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 30),

                        // Save Button
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Saved successfully!")),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Settings Card (Notifications, Security, Language)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.95),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications,
                            color: Colors.deepPurple),
                        title: const Text("Suggestions"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.security,
                            color: Colors.deepPurple),
                        title: const Text("Notification Settings"),

                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.language,
                            color: Colors.deepPurple),
                        title: const Text("Privacy Setting"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
