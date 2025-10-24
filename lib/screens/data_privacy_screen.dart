import 'package:flutter/material.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Data Privacy"),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      children: [
                        const Text(
                          "1. Information We Collect\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // ✅ Personal Information (bold) + details (normal)
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: "Personal Information: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                "name, email address, age, gender, and other details you provide during registration.\n",
                              ),
                              TextSpan(
                                text:
                                "- Account Security Data: login details, verification codes, and two-factor authentication (2FA) information.\n",
                              ),
                              TextSpan(
                                text:
                                "- Health & Activity Data: mood logs, journal entries, chatbot conversations, and personal notes you save.\n",
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "2. How We Use Your Information\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "We use the data we collect to:\n"
                              "- Provide personalized AI-driven mental health support and features.\n"
                              "- Keep your account secure (encryption, authentication, fraud prevention).\n"
                              "- Improve app performance, fix bugs, and develop new features.\n"
                              "- Communicate with you (account verification, updates, or important notices).\n"
                            "We do not sell or share your data with advertisers.\n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "3. Data Storage & Security\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(

                              "- All personal and health-related information is stored in secure, encrypted databases.\n"
                              "- We use secure APIs, access controls, and encryption to protect your data.\n"
                              "- Only authorized NeuroHelp personnel may access data, and only when necessary for support or technical reasons.\n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "4. Sharing of Information\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "We will never sell your information. Your data may only be shared:\n"
                          "- With your explicit consent, or\n"
                              "- When required by law, or\n"
                              "- With trusted third-party services we use (such as cloud hosting or email verification providers), all of which follow strict data protection standards.\n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "5. Your Rights\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Under the Data Privacy Act of 2012 (Philippines) and international privacy principles, you have the right to:\n"
                              "- Access and request a copy of your personal data.\n"
                              "-Correct or update inaccurate information.\n"
                              "- Request deletion of your data (“right to be forgotten”).\n"
                            "- Withdraw your consent to data collection and processing."
                            "You may exercise these rights anytime by contacting us. \n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "6. Data Retention\n",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(

                              "-We keep your personal data only as long as your account is active.\n"
                              "- If you request deletion, your account and all related data will be permanently removed from our systems within a reasonable timeframe.\n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "7. Updates to This Policy",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                              "We may update this Data Privacy Policy from time to time. If significant changes are made, we will notify you through email or in-app notification.\n",
                          style: TextStyle(fontSize: 13),
                        ),

                        const Text(
                          "8. Contact Us",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "If you have any concerns, questions, or requests about your data, please contact us at: 📧 privacy@neurohelp.com\n",
                          style: TextStyle(fontSize: 13),
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
}
