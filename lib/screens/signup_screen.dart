import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController numController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  String? gender;
  bool _isAgreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ------------------ Email/Password Signup ------------------
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAgreed) {
      _showSnackBar("Please agree to the Privacy Policy and Terms.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for existing username
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameController.text.trim())
          .get();

      if (existing.docs.isNotEmpty) {
        _showSnackBar("Username already exists!", Colors.redAccent);
        setState(() => _isLoading = false);
        return;
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user?.sendEmailVerification();

      await FirebaseFirestore.instance.collection('users').add({
        'fullName': fullController.text.trim(),
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'age': int.tryParse(ageController.text) ?? 0,
        'birthday': birthController.text.trim(),
        'gender': gender ?? '',
        'contactNumber': numController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
          "Account created! Please verify your email before logging in.",
          Colors.green);

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Error creating account";
      if (e.code == 'email-already-in-use') message = "Email already in use!";
      if (e.code == 'weak-password') message = "Password is too weak!";
      _showSnackBar(message, Colors.redAccent);
    } catch (e) {
      _showSnackBar("Error: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------ Google Signup ------------------
  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Save user to Firestore if new
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: userCredential.user?.email)
          .get();

      if (userDoc.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('users').add({
          'fullName': userCredential.user?.displayName ?? '',
          'username': userCredential.user?.displayName?.replaceAll(' ', '') ??
              userCredential.user?.uid,
          'email': userCredential.user?.email ?? '',
          'age': 0,
          'birthday': '',
          'gender': '',
          'contactNumber': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      _showSnackBar("Google Sign-In failed: $e", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.deepPurple.shade900, Colors.black]
                : [Colors.deepPurple.shade100, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 20),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.deepPurple.shade800,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(fullController, "Full Name", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(usernameController, "Username", Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(emailController, "Email", Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter your email";
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return "Enter a valid email address";
                          }
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _buildTextField(ageController, "Age", Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter your age";
                          final age = int.tryParse(value);
                          if (age == null || age <= 0) return "Please enter a valid age";
                          return null;
                        }),
                    const SizedBox(height: 16),
                    _buildBirthdayField(),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: _inputDecoration("Gender", Icons.person_2),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) => setState(() => gender = value),
                      validator: (value) => value == null ? "Please select gender" : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(numController, "Contact Number", Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return "Please enter your contact number";
                          if (value.length < 10) return "Enter a valid contact number";
                          return null;
                        }),
                    const SizedBox(height: 30),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: Colors.deepPurple,
                          onChanged: (value) => setState(() => _isAgreed = value ?? false),
                        ),
                        const Expanded(
                          child: Text(
                            "I agree to the Privacy Policy and Terms of Service",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Or continue with",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _signUpWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                      label: const Text("Google"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: Colors.deepPurple),
                      ),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      filled: true,
      fillColor: Colors.white.withOpacity(0.9),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator ?? (value) => value == null || value.isEmpty ? "Please enter $label" : null,
    );
  }

  Widget _buildBirthdayField() {
    return TextFormField(
      controller: birthController,
      readOnly: true,
      decoration: _inputDecoration("Birthday", Icons.cake)
          .copyWith(suffixIcon: const Icon(Icons.calendar_month, color: Colors.deepPurple)),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            birthController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          });
        }
      },
      validator: (value) => value == null || value.isEmpty ? "Please select your birthday" : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: _inputDecoration("Password", Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter a password";
        if (value.length < 6) return "Password must be at least 6 characters";
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmController,
      obscureText: _obscureConfirm,
      decoration: _inputDecoration("Confirm Password", Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (value) {
        if (value != passwordController.text) return "Passwords do not match";
        return null;
      },
    );
  }
}
