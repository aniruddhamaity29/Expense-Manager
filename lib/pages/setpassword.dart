import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/login_screen.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:password_strength_checker/password_strength_checker.dart';

// ignore: must_be_immutable
class Setpassword extends StatefulWidget {
  var email;
  Setpassword({super.key, this.email});

  @override
  State<Setpassword> createState() => _SetpasswordState(email);
}

class _SetpasswordState extends State<Setpassword> {
  final passNotifier = ValueNotifier<PasswordStrength?>(null);
  var email;
  _SetpasswordState(this.email);
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController repasswordcontroller = TextEditingController();
  final formkey = GlobalKey<FormState>();
  bool passwordshow = true, passwordshow1 = true, matchpass = false;
  String matchpassmsg = '';
  FocusNode passwordFocusNode = FocusNode();
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

  Future setPasswordStatus(String email, String password) async {
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
        Uri.parse("${mainurl}change_password.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        print(jsondata);
        Fluttertoast.showToast(
          msg: 'Password set successful',
          textColor: Colors.black,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.white,
        );
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Clears all previous routes
        );
      } else {
        if (!mounted) return;
        Navigator.pop(context);
        print(jsondata['msg']);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
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
                        height: Dimensions.height30,
                      ),
                      SizedBox(
                        child: Image.asset(
                          'asset/images/reset-password.png',
                          width: Dimensions.width180,
                        ),
                      ),
                      SizedBox(
                        height: Dimensions.height5,
                      ),
                      Text(
                        'Reset password',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: Dimensions.font20,
                        ),
                      ),
                      SizedBox(
                        height: Dimensions.height10,
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
                                  return 'Please enter new password';
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
                                hintText: 'New Password',
                                hintStyle: const TextStyle(
                                  color: Colors.black38,
                                ),
                                prefixIcon: const Icon(Icons.password_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.deepPurpleAccent,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(
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
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.black,
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.deepPurpleAccent,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
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
                        visible: true,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            matchpassmsg,
                            style: TextStyle(
                              color: matchpassmsg == 'Password Matched'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: Dimensions.height15),
                        child: ElevatedButton(
                          onPressed: ((matchpassmsg == 'Password Matched') &&
                                  (isPasswordStrong ||
                                      isPasswordSecure ||
                                      isPasswordMedium))
                              ? () {
                                  if (formkey.currentState!.validate() &&
                                      ((matchpassmsg == 'Password Matched') &&
                                          (isPasswordStrong ||
                                              isPasswordSecure ||
                                              isPasswordMedium))) {
                                    setPasswordStatus(
                                        email, passwordcontroller.text);
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            minimumSize:
                                Size(Dimensions.width290, Dimensions.height50),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            'Submit',
                            style: TextStyle(
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
