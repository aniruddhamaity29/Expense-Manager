import 'dart:async';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_application_1/pages/forgotpassword.dart';
import 'package:flutter_application_1/pages/gnav.dart';
import 'package:flutter_application_1/pages/sign_up_screen.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  late SharedPreferences sp;
  bool passwordshow = true;
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  Future getLoginStatus(String email, String password) async {
    Map data = {
      'email': email,
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
        Uri.parse("${mainurl}user_login.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        print(jsondata);
        sp = await SharedPreferences.getInstance();
        sp.setString('email', jsondata['email']);
        sp.setString('username', jsondata['username']);
        sp.setString('user_id', jsondata['id']);
        if (!mounted) return;
        Navigator.pop(context);

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const gNav()));
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text('Incorrect email & password'),
          autoCloseDuration: const Duration(seconds: 4),
          style: ToastificationStyle.flatColored,
          applyBlurEffect: true,
          type: ToastificationType.error,
          icon: Icon(
            Ionicons.close_circle,
            color: Colors.red,
          ),
          pauseOnHover: true,
        );
      }
    } catch (e) {
      print(e);
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
                      'Login to Your Account',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: Dimensions.font20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: Dimensions.height25),
                    Form(
                      key: _formkey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: emailcontroller,
                            focusNode: emailFocusNode,
                            onFieldSubmitted: (value) {
                              // Move focus to the password field when the user submits the email field
                              FocusScope.of(context)
                                  .requestFocus(passwordFocusNode);
                            },
                            validator: (value) {
                              if (value!.isEmpty) {
                                return "Please enter your email";
                              } else if (!RegExp(r'\S+@\S+\.\S+')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              } else {
                                return null;
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.black54,
                              ),
                              filled: false,
                              hintText:
                                  'Email ID', // Changed labelText to hintText
                              hintStyle: TextStyle(
                                color: Colors.black38,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: Dimensions.height15),
                          TextFormField(
                            controller: passwordcontroller,
                            focusNode: passwordFocusNode,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your password';
                              } else {
                                return null;
                              }
                            },
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.password,
                                color: Colors.black54,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    passwordshow = !passwordshow;
                                  });
                                },
                                icon: passwordshow
                                    ? const Icon(Icons.visibility_off)
                                    : const Icon(Icons.visibility),
                              ),
                              filled: false,
                              hintText: 'Password',
                              hintStyle: TextStyle(
                                color: Colors.black38,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            obscureText: passwordshow,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: Dimensions.height15),
                    ElevatedButton(
                      onPressed: () {
                        if (_formkey.currentState!.validate()) {
                          getLoginStatus(
                              emailcontroller.text, passwordcontroller.text);
                          FocusManager.instance.primaryFocus?.unfocus();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: Size(double.infinity, Dimensions.height50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Log In',
                        style: TextStyle(
                            fontSize: Dimensions.font18, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: Dimensions.height15),
                    TextButton(
                      onPressed: () {
                        // Navigate to Forgot Password page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Forgotpassword()),
                        ).then((_) {
                          // Unfocus all fields after coming back
                          FocusManager.instance.primaryFocus?.unfocus();
                        });
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    SizedBox(height: Dimensions.height40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Container(
                          height: Dimensions.height1,
                          width: Dimensions.width100,
                          color: Colors.black,
                        ),
                        const AutoSizeText("OR"),
                        Container(
                          height: Dimensions.height1,
                          width: Dimensions.width100,
                          color: Colors.black,
                        )
                      ],
                    ),
                    SizedBox(height: Dimensions.height10),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SignUpScreen()),
                          (route) => false, // Clears all previous routes
                        );

                        // ).then((_) {
                        //   // Unfocus all fields after coming back
                        //   FocusManager.instance.primaryFocus?.unfocus();
                        // });
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepPurpleAccent),
                        minimumSize: Size(double.infinity, Dimensions.height45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Create new account',
                        style: TextStyle(
                          fontSize: Dimensions.font16,
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
