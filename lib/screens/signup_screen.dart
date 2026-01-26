import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isAgreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _hasReadPolicy = false;

  final TextEditingController fullController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  // Password Strength
  String passwordStrength = "";
  Color strengthColor = Colors.red;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  void checkPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    setState(() {
      if (strength <= 2) {
        passwordStrength = "Weak";
        strengthColor = Colors.red;
      } else if (strength <= 4) {
        passwordStrength = "Medium";
        strengthColor = Colors.orange;
      } else {
        passwordStrength = "Strong";
        strengthColor = Colors.green;
      }
    });

  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isAgreed) {
      await _notificationService.showNotification(
        title: "Agreement Required",
        body: "Please agree to the Privacy Policy and Terms.",
      );
      return;
    }

    if (passwordController.text.trim() != confirmController.text.trim()) {
      await _notificationService.showNotification(
        title: "Password Mismatch",
        body: "Passwords do not match.",
      );
      return;
    }

    if (passwordStrength != "Strong") {
      await _notificationService.showNotification(
        title: "Weak Password",
        body: "Please create a stronger password.",
      );
      setState(() => _isLoading = false);
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => _isLoading = true);

    try {
      // 🔍 Check Firestore first to prevent duplicates
      final existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (existingUser.docs.isNotEmpty) {
        await _notificationService.showNotification(
          title: "Already Registered",
          body: "This email is already registered. Please login instead.",
        );
        setState(() => _isLoading = false);
        return;
      }

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("User creation failed");

      await user.sendEmailVerification();


      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        await userDoc.set({
          'fullName': fullController.text.trim(),
          'email': email,
          'contactNumber': numController.text.trim(),
          'agreedToTerms': _isAgreed,
          'provider': 'password',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _notificationService.showNotification(
        title: "Welcome 🎉",
        body: "Hi ${fullController.text.trim()}, your account was created successfully!",
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Signup failed";

      if (e.code == 'email-already-in-use') {
        message = "Email already in use";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak";
      }

      await _notificationService.showNotification(
        title: "Signup Failed",
        body: message,
      );
    } catch (e) {
      await _notificationService.showNotification(
        title: "Error",
        body: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        signInOption: SignInOption.standard,
      );

      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final email = googleUser.email;


      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        if (doc.data()['provider'] == 'password') {
          await _notificationService.showNotification(
            title: "Already Registered",
            body: "This email is already registered using Email & Password. Please login instead.",
          );
          return;
        }
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'fullName': user.displayName ?? '',
          'email': user.email ?? '',
          'contactNumber': '',
          'agreedToTerms': true,
          'provider': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.update({'provider': 'google'});
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      await _notificationService.showNotification(
        title: "Google Sign-In Failed",
        body: e.toString(),
      );
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy Policy & Terms"),
        content: const SingleChildScrollView(
          child: Text(
            "1. Your privacy is important.\n"
                "2. Terms and conditions apply.\n"
                "3. Make sure to read everything carefully before agreeing.\n\n"

          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _hasReadPolicy = true; //
              });
              Navigator.pop(context);
            },
            child: const Text("I Have Read"),
          ),
        ],
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
                    const Icon(Icons.person_add,
                        size: 80, color: Colors.deepPurple),
                    const SizedBox(height: 20),
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color:
                        isDark ? Colors.white : Colors.deepPurple.shade800,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildTextField(fullController, "Full Name", Icons.person),
                    const SizedBox(height: 16),

                    _buildTextField(
                      emailController,
                      "Email",
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildTextField(
                      numController,
                      "Contact Number",
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your contact number";
                        }
                        if (!RegExp(r'^[0-9]{11}$').hasMatch(value)) {
                          return "Contact number must be 11 digits";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),

                    _buildPasswordField(),
                    const SizedBox(height: 20),

                    _buildConfirmPasswordField(),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: _showTermsDialog,
                      child: const Text(
                        "Read Privacy Policy & Terms",
                        style: TextStyle(
                          color: Colors.deepPurple,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: Colors.deepPurple,
                          onChanged: _hasReadPolicy
                              ? (value) => setState(() => _isAgreed = value ?? false)
                              : null,
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
                      onPressed: (!_isAgreed || _isLoading)
                          ? null
                          : () {
                        if (_formKey.currentState!.validate()) {
                          _registerUser();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isAgreed ? Colors.deepPurple : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white)
                          : const Text(
                        "Sign Up",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        if (!_hasReadPolicy) {
                          _notificationService.showNotification(
                            title: "Read Required",
                            body: "Please read the Privacy Policy & Terms first.",
                          );
                          return;
                        }
                        _signInWithGoogle();
                      },
                      child: Image.asset(
                        'assets/sign_up.png',
                        height: 48,
                      ),
                    ),

                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
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

  @override
  void dispose() {
    fullController.dispose();
    emailController.dispose();
    numController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
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

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {TextInputType keyboardType = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: validator ??
              (value) =>
          value == null || value.isEmpty ? "Please enter $label" : null,
    );
  }

  Widget _buildPasswordField() {
    bool showPasswordUI = passwordController.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: passwordController,
          obscureText: _obscurePassword,
          onChanged: (value) {
            checkPasswordStrength(value);
          },
          decoration: _inputDecoration("Password", Icons.lock).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility),
              color: Colors.grey,
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter a password";
            }
            if (value.length < 8) return "Password must be at least 8 characters";
            if (!RegExp(r'[a-z]').hasMatch(value)) return "Must contain lowercase letter";
            if (!RegExp(r'[A-Z]').hasMatch(value)) return "Must contain uppercase letter";
            if (!RegExp(r'[0-9]').hasMatch(value)) return "Must contain a number";
            if (!RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(value)) {
              return "Must contain special symbol";
            }
            return null;
          },
        ),
        if (!showPasswordUI) const SizedBox.shrink(),
        if (showPasswordUI) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: passwordStrength.isEmpty
                ? 0.0
                : passwordStrength == "Weak"
                ? 0.33
                : passwordStrength == "Medium"
                ? 0.66
                : 1.0,
            color: strengthColor,
            backgroundColor: Colors.grey.shade300,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(height: 8),
          Text(
            "Strength: $passwordStrength",
            style: TextStyle(
              color: strengthColor,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),
          _buildRequirementItem(
            "At least 8 characters",
            passwordController.text.length >= 8,
          ),
          _buildRequirementItem(
            "Contains uppercase (A-Z)",
            RegExp(r'[A-Z]').hasMatch(passwordController.text),
          ),
          _buildRequirementItem(
            "Contains lowercase (a-z)",
            RegExp(r'[a-z]').hasMatch(passwordController.text),
          ),
          _buildRequirementItem(
            "Contains number (0-9)",
            RegExp(r'[0-9]').hasMatch(passwordController.text),
          ),
          _buildRequirementItem(
            "Contains special character",
            RegExp(r'[!@#$%^&*(),.?\":{}|<>]').hasMatch(passwordController.text),
          ),
        ],
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.cancel,
          color: met ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: met ? Colors.green : Colors.red,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmController,
      obscureText: _obscureConfirm,
      decoration: _inputDecoration("Confirm Password", Icons.lock).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
              _obscureConfirm ? Icons.visibility_off : Icons.visibility),
          color: Colors.grey,
          onPressed: () {
            setState(() {
              _obscureConfirm = !_obscureConfirm;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Please confirm your password";
        }
        if (value != passwordController.text) {
          return "Passwords do not match";
        }
        return null;
      },
    );
  }
}