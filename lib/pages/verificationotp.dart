import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/setpassword.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ionicons/ionicons.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:toastification/toastification.dart';

// ignore: must_be_immutable
class Verificationotp extends StatefulWidget {
  var email;
  var jsondata;
  Verificationotp({super.key, this.email, this.jsondata});

  @override
  State<Verificationotp> createState() =>
      _VerificationotpState(email, jsondata);
}

class _VerificationotpState extends State<Verificationotp> {
  var email;
  var jsondata;
  _VerificationotpState(this.email, this.jsondata);
  TextEditingController emailController = TextEditingController();
  TextEditingController otpController = TextEditingController();
  final formkey = GlobalKey<FormState>();
  double h = 0, w = 0;

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

  Future checkOtpStates(String email) async {
    Map data = {
      'email': email,
    };
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const LoadingDialog();
        });
    try {
      var response = await http
          .post(Uri.parse("${mainurl}forgot_password_otp.php"), body: data);
      var jsondata1 = jsonDecode(response.body);
      jsondata = jsondata1;
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: 'The otp is send again',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        textColor: Colors.white,
      );
    } catch (e) {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: "ERROR",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    h = MediaQuery.of(context).size.height;
    w = MediaQuery.of(context).size.width;

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
              automaticallyImplyLeading: false,
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
                        'Verification OTP',
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
                          fieldWidth: Dimensions.height40,
                        ),
                      ),
                      SizedBox(
                        height: Dimensions.height10,
                      ),
                      time != 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Resend Code in",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 3, 3, 3),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(width: 5),
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
                                    checkOtpStates(email);
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
                            if (jsondata['otp'].toString() ==
                                otpController.text) {
                              Fluttertoast.showToast(
                                msg: 'Verification Successful',
                                toastLength: Toast.LENGTH_LONG,
                                gravity: ToastGravity.BOTTOM,
                                textColor: Colors.green,
                                backgroundColor: Colors.white,
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Setpassword(
                                          email: email,
                                        )),
                              );
                            } else {
                              toastification.show(
                                context:
                                    context, // optional if you use ToastificationWrapper
                                title: const Text('Incorrect OTP'),
                                autoCloseDuration: const Duration(seconds: 2),
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
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize:
                                Size(Dimensions.width300, Dimensions.height50),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            'Continue',
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
