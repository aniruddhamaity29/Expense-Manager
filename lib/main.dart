import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/dependency_injection.dart';
import 'package:flutter_application_1/pages/splash_screen.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(Duration(milliseconds: 200));
  runApp(MyApp());
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Expense Manager',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
