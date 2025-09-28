import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms and Conditions"),
        backgroundColor: Colors.white,
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: const [
                    Text(
                        "Welcome to NeuroHelp. By using our app, you agree to follow these Terms & Conditions. "
                            "\nPlease read them carefully before using the service.\n",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                // Card for T&C content
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  color: Colors.white.withOpacity(0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [

                        Text(
                          "1. Acceptance of Terms\n",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "By downloading, accessing, or using NeuroHelp, you agree to these Terms & Conditions. If you do not agree, please stop using the app.\n",
                        ),
                        Text(
                          "2. Purpose of the App\n",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "NeuroHelp is designed to provide AI-driven mental health support, tools, and resources. Important: NeuroHelp is not a substitute for professional medical advice, diagnosis, or treatment. Always seek advice from a licensed healthcare provider for medical concerns.\n",
                        ),
                        Text(
                          "3. User Accounts\n",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "You must provide accurate and truthful information during registration. You are responsible for keeping your login credentials safe. Only verified accounts (via email) can access full features.\n",
                        ),
                        Text(
                          "4. Privacy & Data Security\n",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "We respect your privacy. Personal data and chat logs are stored securely and encrypted. We will not share your data with third parties without your consent, except as required by law. Please review our Privacy Policy for more details.\n",
                        ),
                        Text(
                          "5. User Responsibilities\n",
                              style: TextStyle(
                            fontSize:16,
                          fontWeight: FontWeight.bold,
                        ),

                        ),
                        Text(
                          "When using NeuroHelp, you agree to:"
                              "\nUse the app only for lawful and personal purposes."

                            "\nNot misuse the app for harmful, abusive, or illegal activity."

                            "\nNot attempt to hack, reverse engineer, or disrupt our services.\n",

                        ),
                        Text(
                          "6. Limitations of Service\n",
                          style: TextStyle(
                            fontSize:16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "NeuroHelp provides general wellness support and self-help tools.\n"

                            "We do not guarantee that the app will be error-free or available at all times.\n"

                        "We are not liable for decisions you make based on the app’s suggestions.\n"
                        ),
                        Text("7. Intellectual Property\n",
                        style: TextStyle(
                          fontSize:   16,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                        Text("All app content (logo, design, AI features, text, etc.) belongs to NeuroHelp.\n"

                          "You may not copy, reproduce, or distribute materials without our permission.\n"),

                        Text("8. Changes to Terms\n",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                        Text("We may update these Terms from time to time.\n"

                          "Continued use of NeuroHelp means you accept the updated Terms.\n"),
                        Text("9. Contact Us\n",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                        Text("If you have questions, reach out at 📧 support@neurohelp.com")


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
}
