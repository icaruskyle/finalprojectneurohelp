import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showNotify("Please enter email and password", Colors.red);
      return;
    }

    // 🔐 Check provider first

    setState(() => _isLoading = true);

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final provider = query.docs.first.data()['provider'];

      if (provider == 'google') {
        _showNotify(
          "This account was created using Google. Please login with Google.",
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }
    }


    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user == null) {
        _showNotify("Login failed", Colors.red);
        return;
      }

      if (!user.emailVerified) {
        _showVerificationDialog(user); // 👈 USE THIS
        setState(() => _isLoading = false);
        return;
      }


      await saveUserToFirestore(user);


      _showNotify("Login successful! 🎉", Colors.green);

      await Future.delayed(const Duration(milliseconds: 600));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            name: user.email ?? "",
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _showNotify("Email not registered", Colors.red);
      } else if (e.code == 'wrong-password') {
        _showNotify("Invalid password", Colors.red);
      } else if (e.code == 'account-exists-with-different-credential') {
        _showNotify(
          "This email was registered using Google Sign-In.",
          Colors.orange,
        );
      } else {
        _showNotify("Login failed", Colors.redAccent);
      }
    } catch (e) {
      _showNotify("Something went wrong", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<void> saveUserToFirestore(User user) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'email': user.email,
      'provider': 'password', // 👈 FIXED
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }


  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final email = googleUser.email;

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

// ❌ NOT SIGNED UP
      if (query.docs.isEmpty) {
        _showNotify(
          "No account found. Please sign up first.",
          Colors.redAccent,
        );
        setState(() => _isLoading = false);
        return;
      }

// 🔐 CHECK PROVIDER
      final provider = query.docs.first.data()['provider'];

      if (provider != 'google') {
        _showNotify(
          "This account was created using Email & Password.",
          Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      // ✅ ALLOWED → continue Google auth
      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) throw Exception("Google login failed");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'email': user.email,
        'provider': 'google',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            name: user.email ?? "Google User",
          ),
        ),
      );
    } catch (e) {
      _showNotify("Google login failed", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _showVerificationDialog(User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Email not verified"),
        content: const Text(
          "Please verify your email to continue.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await user.sendEmailVerification();
              _showNotify("Verification email sent 📧", Colors.green);
            },
            child: const Text("Resend"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showNotify(String message, Color color) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3)).then((_) => overlayEntry.remove());
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.deepPurple.shade700.withOpacity(0.4)
                          : Colors.deepPurple.shade100.withOpacity(0.3),
                    ),
                    child: Icon(
                      Icons.health_and_safety,
                      size: 70,
                      color: isDark ? Colors.white : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome Back to NeuroHelp",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "example@gmail.com",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: isDark
                          ? Colors.deepPurple.shade800
                          : Colors.deepPurple.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      filled: true,
                      fillColor: isDark
                          ? Colors.deepPurple.shade800
                          : Colors.deepPurple.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Colors.deepPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "OR",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "If you signed up using Google, please use Google Sign-In.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Image.asset(
                      'assets/sign_in.png',
                      height: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don’t have an account?",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}