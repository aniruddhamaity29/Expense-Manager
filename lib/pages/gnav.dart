import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/tabbar.dart';
import 'package:flutter_application_1/pages/settings.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class gNav extends StatefulWidget {
  const gNav({super.key});

  @override
  State<gNav> createState() => _gNavState();
}

class _gNavState extends State<gNav> {
  int currentIndex = 0;
  Uint8List? profileImage;
  String showImage = "";
  late PageController _pageController;
  late SharedPreferences sp;
  String email = "";
  String userId = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    getData().whenComplete(() {
      getUserImage(email);
    });
  }

  Future<void> getData() async {
    sp = await SharedPreferences.getInstance();
    setState(() {
      email = sp.getString('email') ?? '';
      userId = sp.getString('user_id') ?? '';
    });
  }

  Future<void> getUserImage(String email) async {
    Map data = {'email': email};

    try {
      var response = await http.post(
        Uri.parse("${mainurl}get_user_image.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        setState(() {
          showImage = jsondata['image'].toString();
        });
      } else {
        setState(() {
          showImage = "";
        });
        Fluttertoast.showToast(msg: jsondata['msg']);
      }
    } catch (e) {
      print(e);
    }
  }

  void onTabTapped(int index) async {
    setState(() {
      currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AnimatedOpacity(
            opacity: currentIndex == 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Tabbar(),
          ),
          AnimatedOpacity(
            opacity: currentIndex == 1 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Settings(
              onImageChanged: (img) {
                setState(() {
                  profileImage = img;
                });
              },
              onImageDeleted: () {
                setState(() {
                  showImage = "";
                  profileImage = null;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: GNav(
        backgroundColor: Colors.grey.shade300,
        color: Colors.black,
        activeColor: Colors.amber,
        tabBackgroundColor: Colors.black,
        gap: 3,
        padding: EdgeInsets.all(Dimensions.height15),
        tabMargin: EdgeInsets.all(Dimensions.height5),
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        onTabChange: onTabTapped,
        tabs: [
          const GButton(icon: Icons.home, text: 'Home'),
          GButton(
            icon: Icons.person,
            leading: CircleAvatar(
              radius: 15,
              backgroundImage: profileImage != null
                  ? MemoryImage(profileImage!)
                  : (showImage != ""
                          ? NetworkImage(showImage, scale: 50)
                          : const AssetImage('asset/images/profile.png'))
                      as ImageProvider,
            ),
            text: 'Settings',
          ),
        ],
      ),
    );
  }
}
