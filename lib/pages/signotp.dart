import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/login_screen.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

// ignore: must_be_immutable
class Signotp extends StatefulWidget {
  String email, user_name, password, otp;
  Signotp(this.email, this.otp, this.password, this.user_name, {super.key});

  @override
  State<Signotp> createState() =>
      _SignotpState(email, user_name, password, otp);
}

class _SignotpState extends State<Signotp> {
  String email, user_name, password, otp;
  _SignotpState(this.email, this.otp, this.password, this.user_name);
  TextEditingController emailController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  var jsondata1;
  late Timer timer;
  bool isLoading = false;
  int time = 70;
  void startTimer() {
    const oneSec = Duration(seconds: 1);
    timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (time == 0) {
          setState(() {
            timer.cancel();
            isLoading = false;
          });
        } else {
          setState(() {
            time--;
          });
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future sendOtp(String email, String user_name) async {
    Map data = {
      'email': email,
      'user_name': user_name,
    };
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const LoadingDialog();
        });
    try {
      var response = await http.post(
        Uri.parse("${mainurl}signup_otp.php"),
        body: data,
      );
      var jsondata1 = jsonDecode(response.body);

      if (jsondata1['status'] == true) {
        otp = jsondata1['otp'].toString();
        if (!mounted) return;
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata1['msg']),
          autoCloseDuration: const Duration(seconds: 3),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          icon: const Icon(
            Ionicons.checkmark_circle,
            color: Colors.green,
          ),
          type: ToastificationType.success,
          pauseOnHover: true,
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata1['msg']),
          autoCloseDuration: const Duration(seconds: 3),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          icon: const Icon(
            Ionicons.close_circle,
            color: Colors.red,
          ),
          type: ToastificationType.error,
          pauseOnHover: true,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future getSignUpStatus(
      String email, String user_name, String password) async {
    Map data = {
      'email': email,
      'user_name': user_name,
      'password': password,
    };
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const LoadingDialog();
        });
    try {
      var response = await http.post(
        Uri.parse("${mainurl}user_signup.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: const Text('SignUp Successful'),
          autoCloseDuration: const Duration(seconds: 2),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          icon: const Icon(
            Ionicons.checkmark_circle,
            color: Colors.green,
          ),
          type: ToastificationType.success,
          pauseOnHover: true,
        );

        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Clears all previous routes
        );
      } else {
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),
          autoCloseDuration: const Duration(seconds: 3),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          icon: const Icon(
            Ionicons.close_circle,
            color: Colors.red,
          ),
          type: ToastificationType.error,
          pauseOnHover: true,
        );
      }
    } catch (e) {
      print('Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 252, 155, 203),
                    Color.fromARGB(255, 140, 171, 255)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: const Color.fromARGB(255, 252, 162, 207),
              elevation: 1,
              title: const Text('Expense Manager'),
              centerTitle: false,
            ),
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.width30),
                child: Form(
                  key: formkey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: Dimensions.height250,
                        width: Dimensions.width180,
                        child: Image.asset(
                          'asset/images/verification.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      SizedBox(height: Dimensions.height8),
                      Text(
                        'SignUp with OTP',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimensions.font20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: Dimensions.height8),
                      Text(
                        'Otp has been sent to your email $email',
                        style: TextStyle(fontSize: Dimensions.font15),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(
                        height: Dimensions.height35,
                      ),
                      PinCodeTextField(
                        controller: otpController,
                        appContext: context,
                        // onChanged: (value) {},
                        autoDisposeControllers: false,
                        length: 4,
                        cursorColor: Colors.black,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        keyboardType: TextInputType.number,
                        pinTheme: PinTheme(
                          inactiveColor: Colors.black,
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(5),
                          fieldHeight: Dimensions.height50,
                          fieldWidth: Dimensions.width40,
                        ),
                      ),
                      SizedBox(
                        height: Dimensions.height10,
                      ),
                      time != 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Resend Code in",
                                  style: TextStyle(
                                      color: const Color.fromARGB(255, 3, 3, 3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: Dimensions.font16),
                                ),
                                SizedBox(width: Dimensions.width6),
                                Text(
                                  time == 70 ? '00:70' : '00:$time',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: Dimensions.font20),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't recieve any otp?"),
                                TextButton(
                                  onPressed: () {
                                    sendOtp(email, user_name);
                                    setState(() {
                                      time = 70;
                                      isLoading = true;
                                      startTimer();
                                    });
                                  },
                                  child: Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: Dimensions.font18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      Padding(
                        padding: EdgeInsets.only(top: Dimensions.height20),
                        child: ElevatedButton(
                          onPressed: () {
                            if (otpController.text.isNotEmpty &&
                                formkey.currentState!.validate()) {
                              if (otp == otpController.text) {
                                getSignUpStatus(
                                  email.toString(),
                                  user_name.toString(),
                                  password.toString(),
                                );
                              } else {
                                Fluttertoast.showToast(
                                  msg: 'Incorrect otp',
                                  textColor: Colors.white,
                                  toastLength: Toast.LENGTH_SHORT,
                                  backgroundColor: Colors.red,
                                );
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: 'Please enter OTP',
                                textColor: Colors.black,
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor:
                                    const Color.fromARGB(180, 77, 236, 37),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize:
                                Size(Dimensions.width350, Dimensions.height50),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Dimensions.font20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
