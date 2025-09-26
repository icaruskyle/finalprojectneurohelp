import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  // Call a phone number
  Future<void> _callNumber(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not call $number';
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> contacts = [
      {"name": "National Emergency Hotline", "number": "911"},
      {"name": "Mental Health Crisis Line", "number": "1553"},
      {"name": "Red Cross", "number": "143"},
      {"name": "Suicide Prevention Hotline", "number": "0966-351-4518"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(Icons.phone, color: Colors.deepPurple),
              title: Text(contact["name"] ?? ""),
              subtitle: Text(contact["number"] ?? ""),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => _callNumber(contact["number"] ?? ""),
              ),
            ),
          );
        },
      ),
    );
  }
}
