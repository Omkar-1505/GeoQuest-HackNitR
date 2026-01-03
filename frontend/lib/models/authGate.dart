import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/authScreen.dart';
import 'package:frontend/screens/home.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 3));

    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _openLogin();
    } else {
      _openMainScreen();
    }
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  void _openMainScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //SizedBox(height: 100, child: Image.asset("images/logo.png")),
              SizedBox(height: 20),
              LinearProgressIndicator(
                backgroundColor: const Color.fromARGB(255, 37, 37, 37),
                color: const Color.fromARGB(255, 0, 25, 65), // progress color
                minHeight: 8, // thickness
                borderRadius: BorderRadius.circular(
                  10,
                ), // round edges (Flutter 3.7+)
              ),

              SizedBox(height: 20),
              Column(
                children: [
                  const Text(
                    "GeoQuest",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Explore the world",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
