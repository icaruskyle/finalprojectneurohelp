import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        backgroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE1BEE7)], // light blue → lavender
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.notifications, color: Colors.deepPurple),
                  title: Text("Notifications"),
                  subtitle: Text("Manage notification preferences"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.security, color: Colors.deepPurple),
                  title: Text("Security"),
                  subtitle: Text("Two-factor authentication and login alerts"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.language, color: Colors.deepPurple),
                  title: Text("Language"),
                  subtitle: Text("Change app language"),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
