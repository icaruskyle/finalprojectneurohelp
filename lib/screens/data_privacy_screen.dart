// data_privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DataPrivacyScreen extends StatefulWidget {
  const DataPrivacyScreen({super.key});

  @override
  State<DataPrivacyScreen> createState() => _DataPrivacyScreenState();
}

class _DataPrivacyScreenState extends State<DataPrivacyScreen> {
  bool _isDarkMode = false;
  String _selectedLanguage = 'English';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _auth.currentUser;

    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'English';
    });

    if (user != null) {
      final doc =
      await _firestore.collection('userSettings').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _isDarkMode = data['darkMode'] ?? _isDarkMode;
          _selectedLanguage = data['language'] ?? _selectedLanguage;
        });
      }
    }
  }

  Color get _bgColor => _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
  Color get _cardColor =>
      _isDarkMode ? Colors.deepPurple.shade700.withOpacity(0.9) : Colors.white70;
  Color get _textColor => _isDarkMode ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'Filipino' ? "Privacy ng Data" : "Data Privacy",
        ),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _bgColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: _cardColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "1. Impormasyon na Kinokolekta Namin"
                          : "1. Information We Collect",
                      content: _selectedLanguage == 'Filipino'
                          ? "Personal na Impormasyon: pangalan, email, edad, kasarian, at iba pang detalye na ibinigay mo sa pagrehistro.\n- Account Security Data: login details, verification codes, at two-factor authentication (2FA) information.\n- Health & Activity Data: mood logs, journal entries, chatbot conversations, at personal notes na isinave mo."
                          : "Personal Information: name, email address, age, gender, and other details you provide during registration.\n- Account Security Data: login details, verification codes, and two-factor authentication (2FA) information.\n- Health & Activity Data: mood logs, journal entries, chatbot conversations, and personal notes you save.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "2. Paano Ginagamit ang Iyong Impormasyon"
                          : "2. How We Use Your Information",
                      content: _selectedLanguage == 'Filipino'
                          ? "Ginagamit namin ang data para:\n- Magbigay ng personalized AI-driven mental health support.\n- Panatilihing ligtas ang account.\n- Pagbutihin ang app performance at magdagdag ng features.\n- Makipag-communicate sa user.\nHindi namin ibinebenta ang data mo."
                          : "We use the data we collect to:\n- Provide personalized AI-driven mental health support and features.\n- Keep your account secure.\n- Improve app performance, fix bugs, and develop new features.\n- Communicate with you.\nWe do not sell or share your data with advertisers.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "3. Pag-iimbak at Seguridad ng Data"
                          : "3. Data Storage & Security",
                      content: _selectedLanguage == 'Filipino'
                          ? "- Lahat ng personal at health-related na impormasyon ay naka-encrypt at secure.\n- Ginagamit namin ang secure APIs at access control.\n- Tanging authorized personnel ang may access kung kailangan."
                          : "- All personal and health-related information is stored in secure, encrypted databases.\n- We use secure APIs, access controls, and encryption to protect your data.\n- Only authorized personnel may access data when necessary.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "4. Pagbabahagi ng Impormasyon"
                          : "4. Sharing of Information",
                      content: _selectedLanguage == 'Filipino'
                          ? "Hindi namin ibinebenta ang impormasyon mo. Maaari lang ibahagi:\n- Sa iyong pahintulot.\n- Kung required by law.\n- Sa trusted third-party services."
                          : "We will never sell your information. Your data may only be shared:\n- With your explicit consent, or\n- When required by law, or\n- With trusted third-party services.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "5. Iyong Mga Karapatan"
                          : "5. Your Rights",
                      content: _selectedLanguage == 'Filipino'
                          ? "May karapatan kang i-access, i-update, at i-delete ang data mo. Maaari mong i-withdraw ang consent anytime."
                          : "You have the right to access, update, and delete your data. You may withdraw your consent anytime.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "6. Pagpapanatili ng Data"
                          : "6. Data Retention",
                      content: _selectedLanguage == 'Filipino'
                          ? "- Tinatago namin ang data habang aktibo ang account.\n- Sa deletion request, matatanggal ang lahat ng data."
                          : "- We keep your personal data only as long as your account is active.\n- If you request deletion, all related data will be permanently removed.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "7. Updates sa Policy"
                          : "7. Updates to This Policy",
                      content: _selectedLanguage == 'Filipino'
                          ? "Maaari naming i-update ang policy. Ipapaalam sa inyo kung may malaking pagbabago."
                          : "We may update this Data Privacy Policy from time to time. Users will be notified of major changes.",
                    ),
                    const SizedBox(height: 12),
                    _buildSection(
                      title: _selectedLanguage == 'Filipino'
                          ? "8. Kontakin Kami"
                          : "8. Contact Us",
                      content: _selectedLanguage == 'Filipino'
                          ? "Kung may tanong o concern tungkol sa data mo, email: 📧 privacy@neurohelp.com"
                          : "If you have any concerns or questions about your data, contact: 📧 privacy@neurohelp.com",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(fontSize: 13, color: _textColor, height: 1.4),
        ),
      ],
    );
  }
}
