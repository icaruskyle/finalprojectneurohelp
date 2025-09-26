import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text("Notifications"),
            subtitle: Text("Manage notification preferences"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.security),
            title: Text("Security"),
            subtitle: Text("Two-factor authentication and login alerts"),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
            subtitle: Text("Change app language"),
          ),
        ],
      ),
    );
  }
}
