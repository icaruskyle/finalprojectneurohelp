import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts/Helplines"),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header with icon + title
                Row(
                  children: const [
                    Icon(Icons.local_hospital, color: Colors.deepPurple, size: 32),
                    SizedBox(width: 8),
                    Expanded( // ✅ prevents overflow
                      child: Text(
                        "Mental Health Hotline in the Philippines",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Hotlines in the Philippines for suicide, depression, domestic violence and more",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.teal,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                ),
                const SizedBox(height: 20),

                // --- Hotline Cards ---
                _buildHotlineCard(
                  title: "HOPELINE",
                  numbers: [
                    "(02) 804-4673 (Landline)",
                    "0917-558-4673 (Globe)",
                    "0918-873-4673 (Smart)",
                  ],
                  description:
                  "In Touch: Crisis Line is 24/7 free confidential support over the phone. An automated phone system will inform you that the call will be monitored for quality assurance, but you are allowed to say different names if you don’t like to reveal your name. If you are comfortable with this, you will be asked to stay on the line to be connected to a trained volunteer.",
                  link: "https://www.facebook.com/HopelinePH",
                ),

                const SizedBox(height: 16),

                _buildHotlineCard(
                  title: "In Touch: Crisis Line",
                  numbers: [
                    "(02) 893-7603 (Landline)",
                    "0919-056-0709 (Smart)",
                    "0917-800-1123 (Globe)",
                    "0922-893-8944 (Smart)",
                  ],
                  link: "https://www.facebook.com/InTouchCrisisLine",
                ),

                const SizedBox(height: 25),

                _buildHotlineCard(
                  title: "NCMH Crisis Hotline",
                  numbers: [
                    "(02) 1553 (Luzon landline)",
                    "0917-899-8727 (Globe)",
                    "0908-639-2672 (Smart)",
                  ],
                  description:
                  "An automated phone system will ask you to press 1 for English and press 2 for Filipino so they can connect you to a more suitable volunteer.\n\nSevere psychological and emotional distress, including suicidal ideations. The call will be recorded in accordance with the Data Privacy Act, but gave a reassurance that the conversation will be kept strictly private and confidential.",
                  link: "NCMH Crisis Hotline on Facebook.",
                ),

                const SizedBox(height: 25),

                _buildHotlineCard(
                  title: "MentalHealth PH",
                  numbers: [
                    "(02) 1553",
                    "(02) 7-989-8727",
                    "0917-899-8727",
                  ],
                  link: "https://www.facebook.com/mentalhealthph",
                  description:
                  "MentalHealthPH lies in giving faces and voices to those experiencing mental health concerns—from struggling with the reality of mental ill health, the stigma of needing and seeking help, as well as supporting the people they love.",
                ),

                const SizedBox(height: 25),

                _buildHotlineCard(
                  title: "Bantay Bata Helpline 163",
                  numbers: [
                    "(02) 163 (Landline)",
                  ],
                  link: "https://www.abs-cbnfoundation.com/bantaybata163",
                  description:
                  "Bantay Bata 163 is primarily for parents and children with issues about domestic violence, sexual abuse, and other child-related concerns.",
                ),

                const SizedBox(height: 25),

                _buildHotlineCard(
                  title: "Suicide Crisis Lines",
                  numbers: [
                    "(02) 8893-7603 (Landline)",
                    "0917-8001123 (Globe)",
                    "0917-8001123 (Sun)",
                  ],
                  link: "https://www.facebook.com/InTouchCrisisLine",
                  description:
                  "MentalHealthPH lies in giving faces and voices to those experiencing mental health concerns—from struggling with the reality of mental ill health, the stigma of needing and seeking help, as well as supporting the people they love.",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Custom hotline card widget
  Widget _buildHotlineCard({
    required String title,
    required List<String> numbers,
    String? description,
    String? link,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFE3F2FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            softWrap: true,
          ),
          const SizedBox(height: 8),
          ...numbers.map((number) => Row(
            children: [
              const Icon(Icons.phone, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded( // ✅ fixes overflow
                child: GestureDetector(
                  onTap: () => _callNumber(number),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                    softWrap: true,
                  ),
                ),
              ),
            ],
          )),
          if (description != null) ...[
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
              softWrap: true,
            ),
          ],
          if (link != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _launchURL(link),
              child: const Text(
                "View on Facebook",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
