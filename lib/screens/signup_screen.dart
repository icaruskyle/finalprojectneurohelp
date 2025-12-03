import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification_service.dart';
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
  final TextEditingController birthController = TextEditingController();
  final TextEditingController numController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  String? gender;
  bool _isAgreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Password Strength
  String passwordStrength = "";
  Color strengthColor = Colors.red;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // ---------------- PASSWORD STRENGTH CHECKER ----------------
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

  // ------------------ SIGN UP PROCESS ------------------
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

    final password = passwordController.text.trim();

    // Final password validation
    if (password.length < 8 ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      await _notificationService.showNotification(
        title: "Weak Password",
        body:
        "Password must be 8+ characters with upper, lower, number & symbol.",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usernameInput = usernameController.text.trim();

      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: usernameInput)
          .get();

      if (existing.docs.isNotEmpty) {
        await _notificationService.showNotification(
          title: "Username Taken",
          body: "Username already exists!",
        );
        setState(() => _isLoading = false);
        return;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': fullController.text.trim(),
          'username': usernameInput,
          'email': emailController.text.trim(),
          'birthday': birthController.text.trim(),
          'gender': gender ?? '',
          'contactNumber': numController.text.trim(),
          'agreedToTerms': _isAgreed,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await _notificationService.showNotification(
          title: "Welcome to NeuroHelp 💜",
          body:
          "Hi ${fullController.text.trim()}, your account has been created! Please verify your email.",
        );

        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Error creating account";
      if (e.code == 'email-already-in-use') message = "Email already in use!";
      if (e.code == 'weak-password') message = "Password is too weak!";

      await _notificationService.showNotification(
        title: "Signup Failed",
        body: message,
      );
    } catch (e) {
      await _notificationService.showNotification(
        title: "Signup Failed",
        body: e.toString(),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ------------------ UI ------------------
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
                    _buildTextField(usernameController, "Username", Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a username";
                          }
                          if (value.length < 3) {
                            return "Username must be at least 3 characters";
                          }
                          return null;
                        }),
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
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return "Enter a valid email address";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildBirthdayField(),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: gender,
                      decoration: _inputDecoration("Gender", Icons.person_2),
                      items: const [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) => setState(() => gender = value),
                      validator: (value) =>
                      value == null ? "Please select gender" : null,
                    ),
                    const SizedBox(height: 20),
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

                    // PASSWORD FIELD WITH STRENGTH & CHECKLIST
                    _buildPasswordField(),
                    const SizedBox(height: 20),

                    // CONFIRM PASSWORD
                    _buildConfirmPasswordField(),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          activeColor: Colors.deepPurple,
                          onChanged: (value) =>
                              setState(() => _isAgreed = value ?? false),
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

  // ------------------ HELPER WIDGETS ------------------
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

  Widget _buildBirthdayField() {
    return TextFormField(
      controller: birthController,
      readOnly: true,
      decoration: _inputDecoration("Birthday", Icons.cake).copyWith(
        suffixIcon: const Icon(Icons.calendar_month, color: Colors.deepPurple),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          birthController.text =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        }
      },
      validator: (value) => value == null || value.isEmpty
          ? "Please select your birthday"
          : null,
    );
  }

  // ------------------ PASSWORD FIELD UI ------------------
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
            setState(() {});
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

        // SHOW NOTHING IF PASSWORD FIELD IS EMPTY
        if (!showPasswordUI) const SizedBox.shrink(),

        // SHOW ONLY WHEN TYPING
        if (showPasswordUI) ...[
          const SizedBox(height: 8),

          // PROGRESS BAR
          LinearProgressIndicator(
            value: passwordStrength == "Weak"
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

          // STRENGTH LABEL
          Text(
            "Strength: $passwordStrength",
            style: TextStyle(
              color: strengthColor,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // CHECKLIST REQUIREMENTS
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

  // Checklist item widget
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

  // ------------------ CONFIRM PASSWORD ------------------
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
