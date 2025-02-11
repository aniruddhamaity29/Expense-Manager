import 'dart:convert';
import 'dart:io';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/pages/gnav.dart';
import 'package:flutter_application_1/pages/login_screen.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class Settings extends StatefulWidget {
  final Function(Uint8List) onImageChanged;
  final VoidCallback onImageDeleted;

  const Settings({
    required this.onImageChanged,
    required this.onImageDeleted,
    Key? key,
  }) : super(key: key);

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  TextEditingController emailController = TextEditingController();
  TextEditingController nameController = TextEditingController();

  Uint8List? image;
  File? imageFile;
  String showImage = "";
  late SharedPreferences sp;
  String selectedCurrencyName = 'Select Currency';
  String selectedCurrencySymbol = '';
  bool isEditing = false; // Flag to control editing state

  // Image selection method (Camera/Gallery)
  void selectImage(ImageSource source) async {
    try {
      PermissionStatus status;

      // Check for permissions based on the source (camera or gallery)
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        status = await Permission.storage.request();
      }

      // Handle permission responses
      if (status.isGranted) {
        XFile? pickedFile =
            await ImagePicker().pickImage(source: source, imageQuality: 100);

        if (pickedFile != null) {
          await cropImage(pickedFile.path); // Proceed to cropping
        }
      } else if (status.isDenied) {
        // Permission denied, show error
        toastification.show(
          context: context,
          title: Text('Permission Denied'),
          autoCloseDuration: Duration(seconds: 2),
          style: ToastificationStyle.flatColored,
          icon: Icon(Ionicons.close_circle, color: Colors.red),
          type: ToastificationType.error,
          pauseOnHover: true,
        );
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, ask the user to open app settings
        toastification.show(
          context: context,
          title:
              Text('Permission Permanently Denied. Go to Settings to Enable.'),
          autoCloseDuration: Duration(seconds: 3),
          style: ToastificationStyle.flatColored,
          icon: Icon(Ionicons.close_circle, color: Colors.red),
          type: ToastificationType.error,
          pauseOnHover: true,
        );
        await openAppSettings();
      }
    } catch (e) {
      // Handle any other errors
      toastification.show(
        context: context,
        title: Text('Error: $e'),
        autoCloseDuration: Duration(seconds: 3),
        style: ToastificationStyle.flatColored,
        icon: Icon(Ionicons.close_circle, color: Colors.red),
        type: ToastificationType.error,
        pauseOnHover: true,
      );
    }
  }

  Future<void> cropImage(String filePath) async {
    CroppedFile? croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath,
    );

    if (croppedImage != null) {
      final bytes = await File(croppedImage.path).readAsBytes();
      setState(() {
        image = bytes;
        imageFile = File(croppedImage.path);
      });
      widget.onImageChanged(bytes);
      await saveImageToDatabase();
    }
  }

  Future<void> saveImageToDatabase() async {
    if (imageFile == null) {
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text("No image selected."),

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

      return;
    }
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const LoadingDialog();
        });
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${mainurl}upload_image.php"),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageFile!.readAsBytesSync(),
          filename: imageFile!.path.split("/").last,
        ),
      );
      request.fields['id'] = id;

      var response = await request.send();
      var responded = await http.Response.fromStream(response);
      var jsondata = jsonDecode(responded.body);

      Navigator.pop(context);
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text(jsondata['msg']),
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
    } catch (e) {
      Navigator.pop(context);
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text(e.toString()),

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
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),

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
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteImage() async {
    Map data = {'id': id};

    try {
      var response = await http.post(
        Uri.parse("${mainurl}delete_image.php"),
        body: data,
      );
      var jsondata = jsonDecode(response.body);
      if (jsondata['status'] == true) {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),

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

        setState(() {
          image = null;
          showImage = "";
        });
        widget.onImageDeleted();
      } else {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),

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
    } catch (e) {
      print(e);
    }
  }

  void showImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose an option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera,
                    color: Colors.blue, size: Dimensions.icon35),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  selectImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.image,
                    color: Colors.greenAccent, size: Dimensions.icon35),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  selectImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete,
                    color: Colors.redAccent, size: Dimensions.icon35),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.of(context).pop();
                  deleteImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String email = "";
  String username = "";
  String id = "";

  Future<void> getData() async {
    sp = await SharedPreferences.getInstance();
    setState(() {
      email = sp.getString('email') ?? '';
      emailController.text = email;
      username = sp.getString('username') ?? '';
      nameController.text = username;
      id = sp.getString('user_id') ?? '';
    });
  }

  @override
  void initState() {
    getData().whenComplete(() => getUserImage(email));
    _loadSelectedCurrency();
    super.initState();
  }

  Future<void> _loadSelectedCurrency() async {
    sp = await SharedPreferences.getInstance();
    String? currency = sp.getString('currency');
    String? CurrencyName = sp.getString('currency_name');
    if (currency != null && CurrencyName != null) {
      setState(() {
        selectedCurrencySymbol = currency;
        selectedCurrencyName = CurrencyName;
      });
    }
  }

  void logOut() async {
    sp = await SharedPreferences.getInstance();
    sp.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.logout,
              size: Dimensions.icon50,
              color: Colors.redAccent,
            ),
            SizedBox(height: Dimensions.height10),
            Text(
              'L O G O U T',
              style: TextStyle(
                fontSize: Dimensions.font24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: Dimensions.font16,
            color: Colors.black54,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: EdgeInsets.symmetric(vertical: Dimensions.height15),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: Size(Dimensions.width100, Dimensions.height40),
              elevation: 3,
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black,
                fontSize: Dimensions.font14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: logOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: Size(Dimensions.width100, Dimensions.height40),
              elevation: 3,
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.black,
                fontSize: Dimensions.font14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updateUserProfile(String name) async {
    Map data = {
      'username': name,
      'user_id': id,
    };
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const LoadingDialog();
        });
    try {
      var response = await http
          .post(Uri.parse("${mainurl}user_profile_update.php"), body: data);
      var jsondata = jsonDecode(response.body);
      if (jsondata['status']) {
        sp = await SharedPreferences.getInstance();
        setState(() {
          sp.setString("username", jsondata['data']['user_name']);
          username = jsondata['data']['user_name']; // Update local state
        });
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),

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
        setState(() {
          isEditing = false; // Disable editing after update
        });
      } else {
        Navigator.pop(context);
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text(jsondata['msg']),

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
    } catch (e) {
      Navigator.pop(context);
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text(e.toString()),

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
  }

  Future deleteAccount() async {
    final response = await http.post(
      Uri.parse("${mainurl}delete_account.php"),
      body: {'email': emailController.text},
    );
    if (response.statusCode == 200) {
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text('Account deleted successfully!'),

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
      logOut();
    } else {
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text('Failed to delete account. Try Again.'),

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
  }

  void showConfirmationDialog(String action) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('$action Confirmation'),
            content: Text(
              'Are you sure you want to $action your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  deleteAccount();
                },
                child: Text('Confirm'),
              ),
            ],
          );
        });
  }

  void showAboutUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Colors.blueAccent,
              ),
              SizedBox(width: 8),
              Text(
                'About Us',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Expense Manager helps you track income and expenses effortlessly. Gain real-time insights into your financial status.",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Our Mission:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "To simplify money management and help users achieve financial stability.",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showHelpSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Text(
                'Help & Support',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              helpItem("How to Add an Expense?",
                  "Tap the '+' button, enter details, and save."),
              helpItem("How to View Past Transactions?",
                  "Go to the 'Statistics' tab for financial insights."),
              helpItem("How is Balance Calculated?",
                  "Balance = Total Income - Total Expense."),
              helpItem("How to Change Currency?",
                  "Go to 'Settings' > Select currency > Restart app."),
              SizedBox(height: 10),
              Text(
                "Need More Help? Contact support@example.com",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget helpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(description,
              style: TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        onPopInvoked: (didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => gNav()),
          );
        },
        canPop: false,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Courier New',
                fontSize: Dimensions.font26,
              ),
            ),
            backgroundColor: Colors.purple[200],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(Dimensions.height10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: showImageDialog,
                    child: CircleAvatar(
                      radius: Dimensions.width80,
                      backgroundImage: image != null
                          ? MemoryImage(image!)
                          : showImage.isNotEmpty
                              ? NetworkImage(showImage)
                              : const AssetImage('asset/images/profile.png')
                                  as ImageProvider,
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.height10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    isEditing
                        ? Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(left: Dimensions.width50),
                              child: TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(left: Dimensions.width30),
                            child: Text(
                              "Name: $username",
                              style: TextStyle(fontSize: Dimensions.font16),
                            ),
                          ),
                    Padding(
                      padding: EdgeInsets.only(right: Dimensions.width15),
                      child: IconButton(
                        icon: Icon(isEditing
                            ? Icons.check
                            : Icons.edit), // Change icon based on editing state
                        onPressed: () {
                          if (isEditing) {
                            // Save changes when in editing mode
                            updateUserProfile(nameController.text);
                          } else {
                            setState(() {
                              isEditing = true; // Enable editing
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    "Email: $email",
                    style: TextStyle(fontSize: Dimensions.font16),
                  ),
                ),
                SizedBox(height: Dimensions.height30),
                Text('Settings',
                    style: TextStyle(
                        fontSize: Dimensions.font20,
                        fontWeight: FontWeight.w400)),
                SizedBox(height: Dimensions.height20),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: Dimensions.width50,
                            height: Dimensions.height50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.currency_exchange_outlined,
                                color: Colors.black54),
                          ),
                          SizedBox(width: Dimensions.width6),
                          Text('Currency',
                              style: TextStyle(
                                  fontSize: Dimensions.font18,
                                  fontWeight: FontWeight.w400)),
                          const Spacer(),
                          Column(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  showCurrencyPicker(
                                    context: context,
                                    showFlag: true,
                                    showSearchField: true,
                                    showCurrencyName: true,
                                    showCurrencyCode: true,
                                    onSelect: (Currency currency) {
                                      setState(() {
                                        selectedCurrencyName = currency
                                            .name; // Store the currency name
                                        selectedCurrencySymbol = currency
                                            .symbol; // Store the currency symbol
                                      });
                                      sp.setString('currency', currency.symbol);
                                      sp.setString(
                                          'currency_name', currency.name);
                                      toastification.show(
                                        context:
                                            context, // optional if you use ToastificationWrapper
                                        title:
                                            const Text("Currency updated to"),
                                        description: Text(
                                            "${currency.name}(${currency.symbol})"),
                                        autoCloseDuration:
                                            const Duration(seconds: 2),
                                        style: ToastificationStyle.flatColored,
                                        applyBlurEffect: true,
                                        icon: const Icon(
                                          Ionicons.checkmark_circle,
                                          color: Colors.green,
                                        ),
                                        type: ToastificationType.success,
                                        pauseOnHover: true,
                                      );
                                    },
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(selectedCurrencySymbol.isNotEmpty
                                        ? '$selectedCurrencyName($selectedCurrencySymbol)'
                                        : 'Select Currency'),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                              Container(
                                height: Dimensions.height1,
                                width: Dimensions.width120,
                                decoration:
                                    const BoxDecoration(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: Dimensions.height5),
                      Row(
                        children: [
                          Container(
                            width: Dimensions.width50,
                            height: Dimensions.height50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Ionicons.trash_outline,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: Dimensions.width6),
                          Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: Dimensions.font18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                showConfirmationDialog('Delete');
                              },
                              icon: const Icon(Icons.arrow_forward_ios)),
                        ],
                      ),
                      SizedBox(height: Dimensions.height5),
                      Row(
                        children: [
                          Container(
                            width: Dimensions.width50,
                            height: Dimensions.height50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.help_outline,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: Dimensions.width6),
                          Text(
                            'Help & Support',
                            style: TextStyle(
                              fontSize: Dimensions.font18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                showHelpSupport(context);
                              },
                              icon: const Icon(Icons.arrow_forward_ios)),
                        ],
                      ),
                      SizedBox(height: Dimensions.height5),
                      Row(
                        children: [
                          Container(
                            width: Dimensions.width50,
                            height: Dimensions.height50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: Dimensions.width6),
                          Text(
                            'About Us',
                            style: TextStyle(
                              fontSize: Dimensions.font18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                showAboutUs(context);
                              },
                              icon: Icon(Icons.arrow_forward_ios)),
                        ],
                      ),
                      SizedBox(height: Dimensions.height5),
                      Row(
                        children: [
                          Container(
                            width: Dimensions.width50,
                            height: Dimensions.height50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.logout_outlined,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(width: Dimensions.width6),
                          Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontSize: Dimensions.font18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                showLogoutDialog(context);
                              },
                              icon: Icon(Icons.arrow_forward_ios)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
