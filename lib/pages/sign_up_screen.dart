import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/login_screen.dart';
import 'package:flutter_application_1/pages/signotp.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_1/utils/url.dart';
import 'package:ionicons/ionicons.dart';
import 'package:password_strength_checker/password_strength_checker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:toastification/toastification.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final passNotifier = ValueNotifier<PasswordStrength?>(null);
  final _formkey = GlobalKey<FormState>();
  bool passwordshow = true, passwordshow1 = true, matchpass = false;
  String matchpassmsg = '';
  TextEditingController usernamecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController repasswordcontroller = TextEditingController();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode nameFocusNode = FocusNode();
  FocusNode confirmPasswordFocusNode = FocusNode();
  bool isPasswordStrong = false,
      isPasswordSecure = false,
      isPasswordMedium = false;

  bool isPasswordFocused = false,
      isConfirmPasswordFocused =
          false; // To track the focus state of the password field

  @override
  void initState() {
    super.initState();

    // Add listener to focus node to track focus change
    passwordFocusNode.addListener(() {
      setState(() {
        isPasswordFocused = passwordFocusNode.hasFocus;
      });
    });
    confirmPasswordFocusNode.addListener(() {
      setState(() {
        isConfirmPasswordFocused = confirmPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Dispose the focus nodes to avoid memory leaks
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Future signUpOtp(String email, String user_name) async {
    Map data = {
      'email': email,
      'user_name': user_name,
    };
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Sending otp',
      text: 'Please wait...',
    );
    try {
      var response = await http.post(
        Uri.parse("${mainurl}signup_otp.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: const Text('OTP has been sent to your'),
          description: const Text('registered Email ID'),
          autoCloseDuration: const Duration(seconds: 4),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          icon: const Icon(
            Ionicons.checkmark_circle,
            color: Colors.green,
          ),
          type: ToastificationType.success,
          pauseOnHover: true,
        );

        if (!mounted) return;
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => Signotp(
                      emailcontroller.text,
                      usernamecontroller.text,
                      passwordcontroller.text,
                      jsondata['otp'].toString(),
                    )));
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: const Text('Your email id already exist'),
          autoCloseDuration: const Duration(seconds: 4),
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
      print("Error: $e");
      if (!mounted) return;
      Navigator.pop(context);
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text(e.toString()),
        autoCloseDuration: const Duration(seconds: 4),
        style: ToastificationStyle.flatColored,
        icon: const Icon(
          Ionicons.close_circle,
          color: Colors.red,
        ),
        applyBlurEffect: true,
        type: ToastificationType.error,
        pauseOnHover: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        // FocusManager.instance.primaryFocus?.unfocus();
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
                  key: _formkey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: Dimensions.height150,
                        width: Dimensions.width100,
                        child: Image.asset(
                          'asset/images/finance_management.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      Text(
                        'Create your Account',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: Dimensions.font20,
                        ),
                      ),
                      SizedBox(height: Dimensions.height10),
                      Padding(
                        padding: EdgeInsets.all(Dimensions.height8),
                        child: TextFormField(
                          controller: usernamecontroller,
                          focusNode: nameFocusNode,
                          onFieldSubmitted: (value) {
                            // Move focus to the password field when the user submits the email field
                            FocusScope.of(context).requestFocus(emailFocusNode);
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter username';
                            } else {
                              return null;
                            }
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Dimensions.height8),
                        child: TextFormField(
                          controller: emailcontroller,
                          focusNode: emailFocusNode,
                          onFieldSubmitted: (value) {
                            // Move focus to the password field when the user submits the email field
                            FocusScope.of(context)
                                .requestFocus(passwordFocusNode);
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your email';
                            } else if (!RegExp(r'\S+@\S+\.\S+')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            } else {
                              return null;
                            }
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            hintText: 'Email ID',
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Dimensions.height8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: passwordcontroller,
                              focusNode: passwordFocusNode,
                              onFieldSubmitted: (value) {
                                // Move focus to the confirm password field
                                FocusScope.of(context)
                                    .requestFocus(confirmPasswordFocusNode);
                              },
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              decoration: InputDecoration(
                                suffixIcon: isPasswordFocused
                                    ? IconButton(
                                        onPressed: () {
                                          setState(() {
                                            passwordshow = !passwordshow;
                                          });
                                        },
                                        icon: passwordshow
                                            ? const Icon(Icons.visibility_off)
                                            : const Icon(Icons.visibility),
                                      )
                                    : null,
                                hintText: 'Password',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                prefixIcon: const Icon(Icons.password_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.deepPurpleAccent,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              obscureText: passwordshow,
                              onChanged: (value) {
                                passNotifier.value =
                                    PasswordStrength.calculate(text: value);
                                setState(() {
                                  if (repasswordcontroller.text.isEmpty) {
                                    matchpass = true;
                                    matchpassmsg = '';
                                  } else if (passwordcontroller.text ==
                                      repasswordcontroller.text) {
                                    matchpass = true;
                                    matchpassmsg = 'Password Matched';
                                  } else {
                                    matchpass = true;
                                    matchpassmsg = 'Password didn\'t Match';
                                  }
                                  isPasswordStrong = passNotifier.value ==
                                      PasswordStrength.strong;
                                  isPasswordSecure = passNotifier.value ==
                                      PasswordStrength.secure;
                                  isPasswordMedium = passNotifier.value ==
                                      PasswordStrength.medium;
                                });
                              },
                            ),
                            Visibility(
                              visible: passwordcontroller.text.isNotEmpty,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: PasswordStrengthChecker(
                                      strength: passNotifier,
                                      configuration:
                                          PasswordStrengthCheckerConfiguration(
                                              statusMargin: EdgeInsets.only(
                                                  top: Dimensions.height1,
                                                  left: Dimensions.width2),
                                              height: Dimensions.height15),
                                    ),
                                  ),
                                  PopupMenuButton(
                                      color: Colors.white,
                                      // : Colors.white,
                                      icon: const Icon(Icons.help_outline),
                                      iconSize: Dimensions.icon18,
                                      elevation: 5,
                                      // surfaceTintColor: Colors.white,
                                      itemBuilder: (context) => [
                                            PopupMenuItem(
                                              enabled: false,
                                              child: Text(PasswordStrength
                                                  .instructions),
                                              // value: 1,
                                            )
                                          ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Dimensions.height8),
                        child: TextFormField(
                          controller: repasswordcontroller,
                          focusNode: confirmPasswordFocusNode,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            suffixIcon: isConfirmPasswordFocused
                                ? IconButton(
                                    onPressed: () {
                                      setState(() {
                                        passwordshow1 = !passwordshow1;
                                      });
                                    },
                                    icon: passwordshow1
                                        ? const Icon(Icons.visibility_off)
                                        : const Icon(Icons.visibility),
                                  )
                                : null,
                            hintText: 'Confirm password',
                            hintStyle: const TextStyle(
                              color: Colors.black38,
                            ),
                            prefixIcon: const Icon(Icons.password_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.deepPurpleAccent,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                            ),
                          ),
                          obscureText: passwordshow1,
                          onChanged: (value) {
                            setState(() {
                              if (repasswordcontroller.text.isEmpty) {
                                matchpass = true;
                                matchpassmsg = '';
                              } else if (passwordcontroller.text ==
                                  repasswordcontroller.text) {
                                matchpass = true;
                                matchpassmsg = 'Password Matched';
                              } else {
                                matchpass = true;
                                matchpassmsg = 'Password didn\'t Match';
                              }
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: Dimensions.height2,
                      ),
                      Visibility(
                        visible: matchpass,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              matchpassmsg,
                              style: TextStyle(
                                color: matchpassmsg == 'Password Matched'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            )),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: Dimensions.height40),
                        child: ElevatedButton(
                          onPressed: ((matchpassmsg == 'Password Matched') &&
                                  (isPasswordStrong ||
                                      isPasswordSecure ||
                                      isPasswordMedium))
                              ? () {
                                  if (_formkey.currentState!.validate() &&
                                      (matchpassmsg == 'Password Matched') &&
                                      (isPasswordStrong ||
                                          isPasswordSecure ||
                                          isPasswordMedium)) {
                                    signUpOtp(emailcontroller.text,
                                        usernamecontroller.text);
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize:
                                Size(Dimensions.width290, Dimensions.height50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Sign Up',
                            style: TextStyle(fontSize: Dimensions.font18),
                          ),
                        ),
                      ),
                      SizedBox(height: Dimensions.height30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: Dimensions.font15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: Dimensions.width6),
                          InkWell(
                            onTap: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const LoginScreen()),
                                (route) => false, // Clears all previous routes
                              );
                            },
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.normal,
                                fontSize: Dimensions.font20,
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
        ],
      ),
    );
  }
}
