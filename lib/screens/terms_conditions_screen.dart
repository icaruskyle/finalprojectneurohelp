import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
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
  Color get _textColor => _isDarkMode ? Colors.white : Colors.black87;
  Color get _cardColor =>
      _isDarkMode ? Colors.deepPurple.shade700.withOpacity(0.9) : Colors.white70;

  Widget _buildSection(String title, String content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.purpleAccent : Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 15,
                color: _textColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final welcomeText = _selectedLanguage == 'Filipino'
        ? "Maligayang pagdating sa NeuroHelp! Sa paggamit ng aming app, sumasang-ayon ka sa mga Terms & Conditions. Basahin ito nang maingat upang maunawaan ang iyong mga karapatan at responsibilidad.\n"
        : "Welcome to NeuroHelp! By using our app, you agree to follow these Terms & Conditions. Please read them carefully to understand your rights and responsibilities.\n";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedLanguage == 'Filipino' ? "Mga Termino at Kondisyon" : "Terms and Conditions",
        ),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: _isDarkMode
              ? const LinearGradient(
            colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.deepPurple.shade200, Colors.purpleAccent.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  welcomeText,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),

                // Sections
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "1. Pagtanggap sa Termino"
                      : "1. Acceptance of Terms",
                  _selectedLanguage == 'Filipino'
                      ? "Sa pag-download, pag-access, o paggamit ng NeuroHelp, kinikilala mo na nabasa, naintindihan, at sumasang-ayon ka sa Terms & Conditions na ito. Kung hindi ka sumasang-ayon, itigil agad ang paggamit ng app."
                      : "By downloading, accessing, or using NeuroHelp, you acknowledge that you have read, understood, and agree to these Terms & Conditions. If you do not agree, please stop using the app immediately.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "2. Layunin ng App"
                      : "2. Purpose of the App",
                  _selectedLanguage == 'Filipino'
                      ? "Nagbibigay ang NeuroHelp ng AI-driven tools, gabay, at mental wellness resources upang suportahan ang self-care, emotional awareness, at stress management. Ang NeuroHelp ay HINDI pamalit sa professional medical o psychological advice."
                      : "NeuroHelp provides AI-driven tools, guidance, and mental wellness resources to support self-care, emotional awareness, and stress management. Important: NeuroHelp is NOT a substitute for professional medical or psychological advice.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "3. User Accounts"
                      : "3. User Accounts",
                  _selectedLanguage == 'Filipino'
                      ? "Dapat magrehistro ang mga user ng tama at totoo na impormasyon. Responsable ka sa seguridad ng iyong login credentials at lahat ng aktibidad sa account."
                      : "Users must register with accurate personal information. You are responsible for maintaining your login credentials and all activity associated with your account.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "4. Privacy at Seguridad ng Data"
                      : "4. Privacy & Data Security",
                  _selectedLanguage == 'Filipino'
                      ? "Pinahahalagahan namin ang iyong privacy at seguridad. Lahat ng personal data ay naka-encrypt at secure. Hindi namin ibinabahagi ang data mo nang walang pahintulot, maliban kung required by law."
                      : "We prioritize your privacy and the security of your data. All personal information is stored securely and encrypted. We do not share your data without your consent except as required by law.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "5. Responsibilidad ng User"
                      : "5. User Responsibilities",
                  _selectedLanguage == 'Filipino'
                      ? "Sumasang-ayon ka na:\n- Gamitin ang app nang legal at personal.\n- Iwasan ang maling paggamit o ilegal na aktibidad.\n- Huwag subukang i-hack o i-disrupt ang serbisyo."
                      : "By using NeuroHelp, you agree to:\n- Use the app for personal, lawful purposes.\n- Avoid misuse or illegal activity.\n- Refrain from hacking or disrupting the app's services.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "6. Limitasyon ng Serbisyo"
                      : "6. Limitations of Service",
                  _selectedLanguage == 'Filipino'
                      ? "Nagbibigay ang app ng general wellness support. Hindi kami responsable sa anumang error, outage, o desisyon mo base sa app content."
                      : "NeuroHelp provides general wellness support. We are not responsible for errors, outages, or decisions made based on the app content.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "7. Intellectual Property"
                      : "7. Intellectual Property",
                  _selectedLanguage == 'Filipino'
                      ? "Lahat ng content sa app ay pag-aari ng NeuroHelp at protektado ng copyright. Hindi puwedeng kopyahin o i-distribute nang walang pahintulot."
                      : "All content within the app is owned by NeuroHelp and protected by copyright. You may not copy or distribute without permission.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "8. User-Generated Content"
                      : "8. User-Generated Content",
                  _selectedLanguage == 'Filipino'
                      ? "Ang mga journal entry o personal content mo ay mananatiling pribado maliban kung ibahagi mo. Ibinibigay mo sa NeuroHelp ang non-exclusive license para magamit sa app functionality."
                      : "Your journal entries and personal content remain private unless shared. You grant NeuroHelp a non-exclusive license to use content for app functionality.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "9. Notifications & Tracking"
                      : "9. Notifications & Tracking",
                  _selectedLanguage == 'Filipino'
                      ? "Maaaring magpadala ang app ng reminders o usage tracking. Hindi kabilang ang personally identifiable info. Puwede mong i-on/off sa settings."
                      : "The app may send reminders or track usage for performance. No personally identifiable info is collected. Can be enabled/disabled in settings.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "10. Pagbabago sa Termino"
                      : "10. Changes to Terms",
                  _selectedLanguage == 'Filipino'
                      ? "Maaaring i-update ang Terms & Conditions. Ang patuloy na paggamit ng app ay nangangahulugang pagtanggap sa updates."
                      : "We may update these Terms & Conditions. Continued use indicates acceptance of updates.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "11. Disclaimer"
                      : "11. Disclaimer",
                  _selectedLanguage == 'Filipino'
                      ? "Ang app ay nagbibigay ng general mental wellness guidance at hindi pamalit sa professional care. Hindi kami responsable sa anumang pinsala o distress."
                      : "The app provides general mental wellness guidance and is not a substitute for professional care. We are not responsible for any harm or distress.",
                ),
                _buildSection(
                  _selectedLanguage == 'Filipino'
                      ? "12. Kontakin Kami"
                      : "12. Contact Us",
                  _selectedLanguage == 'Filipino'
                      ? "Para sa katanungan, email: 📧 support@neurohelp.com"
                      : "For questions or concerns, contact: 📧 support@neurohelp.com",
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
