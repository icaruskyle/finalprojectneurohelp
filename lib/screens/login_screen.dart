import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;

  void _login() {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username == "user" && password == "1234") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(username: username)),
      );
    } else {
      setState(() {
        errorMessage = "Invalid username or password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety, size: 80, color: Colors.deepPurple),
              SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              SizedBox(height: 30),

              // Username field
              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 20),

              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // 👈 force white text
                    fontWeight: FontWeight.bold, // (optional) makes it stand out more
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}
