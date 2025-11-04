import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';

class AccountDeleteHelper {
  static Future<void> confirmAndDeleteAccount(BuildContext context) async {
    int countdown = 5;
    bool confirmed = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (countdown > 0) setState(() => countdown--);
            });

            return AlertDialog(
              title: const Text("Delete Account"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "This will permanently delete your account and all data.\n\n"
                        "This action cannot be undone.",
                  ),
                  const SizedBox(height: 15),
                  Text(
                    countdown > 0
                        ? "Please wait $countdown seconds before confirming..."
                        : "You can now confirm deletion.",
                    style: TextStyle(
                      color: countdown > 0 ? Colors.redAccent : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: countdown > 0
                      ? null
                      : () {
                    confirmed = true;
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Delete Account"),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed) {
      await _reauthenticateAndDeleteUser(context);
    }
  }

  static Future<void> _reauthenticateAndDeleteUser(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final firestore = FirebaseFirestore.instance;
      if (user == null) return;

      // Reauthentication
      final providerData = user.providerData.first;
      if (providerData.providerId == 'password') {
        String? email = user.email;
        String? password;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final TextEditingController passController = TextEditingController();
            return AlertDialog(
              title: const Text("Reauthenticate"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Please re-enter your password for $email to continue."),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, passController.text),
                  child: const Text("Confirm"),
                ),
              ],
            );
          },
        ).then((value) => password = value);

        if (password == null || password!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Reauthentication canceled")),
          );
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: email!,
          password: password!,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (providerData.providerId == 'google.com') {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      }

      // Delete user data
      final uid = user.uid;
      final collections = ['users', 'journals', 'moods', 'feedbacks'];
      for (final col in collections) {
        final snapshots = await firestore
            .collection(col)
            .where('userId', isEqualTo: uid)
            .get();
        for (final doc in snapshots.docs) {
          await firestore.collection(col).doc(doc.id).delete();
        }
      }

      await user.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Account deleted successfully."),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error deleting account: $e")),
      );
    }
  }
}
