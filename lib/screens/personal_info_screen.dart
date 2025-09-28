import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Information"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Update your personal details here:",
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),

            // Full Name
            TextField(
              decoration: InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
              ),
              items: const [
                DropdownMenuItem(value: "Male", child: Text("Male")),
                DropdownMenuItem(value: "Female", child: Text("Female")),
                DropdownMenuItem(value: "Other", child: Text("Other")),
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
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Saved successfully!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save"),
            ),
            const SizedBox(height: 30),

            // Links Section
            const Divider(),
            ListTile(
              leading: const Icon(Icons.feedback, color: Colors.deepPurple),
              title: const Text("Suggestions"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Add your suggestion link navigation here
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.deepPurple),
              title: const Text("Notification Settings"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to Notification screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.deepPurple),
              title: const Text("Privacy Settings"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to Privacy screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
