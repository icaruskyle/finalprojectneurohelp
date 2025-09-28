import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'welcome_screen.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController fullController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController numController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isAgreed = false; // for checkbox for agreement

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_add, size: 80, color: Colors.deepPurple),
                SizedBox(height: 20),
                Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                SizedBox(height: 30),

                //FullName
                TextField(
                  controller: fullController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 16),

                //UserName
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

                // Email field
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                SizedBox(height: 16),

                //Age
                TextField(
                  controller: ageController,
                  decoration: InputDecoration (
                    labelText: "Age",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.numbers_rounded)
                  ),
                ),
                SizedBox(height: 16),

                //birthday
                TextField(
                  controller: birthController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Birthday (MM/DD/YYYY)",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 20),

                //gender
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.person_2_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],
                  onChanged: (value) {},
                ),
                const SizedBox(height: 20),

              // Contact Number
                TextField(
                  decoration: InputDecoration(
                    labelText: "Contact Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.contacts),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),

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

                //Confirm Password Field
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.lock_outlined)
                  ),
                ),
                SizedBox(height: 20),

                //checkbox for agreement of privacy
                Row(
                  children: [
                    Checkbox(
                    value: _isAgreed,
                      activeColor: Colors.deepPurple,
                      onChanged: (value) {
                      setState(() {
                        _isAgreed = value ?? false;
                      });
                    },
                    ),
                    Expanded (
                      child: Text(
                        "I Agree to the Privacy Policy and Terms of Service",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isAgreed? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => WelcomeScreen()),
                    );
                  }
                  :null, // disabled the checkbox
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text("Sign Up", style: TextStyle(fontSize: 18,
                    color: Colors.white, // 👈 force white text
                    fontWeight: FontWeight.bold,)),
                ),

                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.deepPurple),
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
