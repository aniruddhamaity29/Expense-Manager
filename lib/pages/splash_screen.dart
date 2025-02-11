import 'dart:async';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_application_1/pages/gnav.dart';
import 'package:flutter_application_1/pages/onboardingscreen.dart';
import 'package:flutter_application_1/utils/values.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late SharedPreferences sp;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    navigateToLogin();
  }

  navigateToLogin() async {
    sp = await SharedPreferences.getInstance();
    String email = sp.getString('email') ?? '';
    timer = Timer.periodic(Duration(milliseconds: 100), (timer) async {
      if (x == 1) {
        timer.cancel();
        await Future.delayed(Duration(seconds: 1), () {
          if (email.isEmpty) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OnboardingScreen()),
            );
          } else {
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => gNav()),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 252, 155, 203),
              Color.fromARGB(255, 140, 171, 255)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'asset/images/finance_management.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(
                height: 10,
              ),
              const AutoSizeText(
                'Expense Manager',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Courier New',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
