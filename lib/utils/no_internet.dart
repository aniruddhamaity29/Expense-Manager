import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:lottie/lottie.dart';

class NoInternetPage extends StatelessWidget {
  const NoInternetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation for no internet
              Lottie.asset(
                "asset/animation/noInternet.json",
                width: MediaQuery.of(context).size.width * 1,
                // height: MediaQuery.of(context).size.width * 0.9,
                // fit: BoxFit.contain,
              ),
              Text(
                "Please check your connection and try again.",
                style: TextStyle(
                  fontSize: Dimensions.font14,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
