import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_application_1/utils/no_internet.dart';
import 'package:flutter_application_1/utils/values.dart';
import 'package:get/get.dart';

class NetworkController extends GetxController {
  Connectivity connectivity = Connectivity();
  @override
  void onInit() {
    try {
      connectivity.onConnectivityChanged.listen((event) {
        if (!event.contains(ConnectivityResult.mobile) &&
            !event.contains(ConnectivityResult.wifi) &&
            !event.contains(ConnectivityResult.ethernet)) {
          x = 0;
          Get.to(() => const NoInternetPage());
          // Get.rawSnackbar(
          //     messageText: const Text('PLEASE CONNECT TO THE INTERNET',
          //         style: TextStyle(color: Colors.white, fontSize: 14)),
          //     isDismissible: false,
          //     duration: const Duration(days: 1),
          //     backgroundColor: Colors.red[400]!,
          //     icon: const Icon(
          //       Icons.wifi_off,
          //       color: Colors.white,
          //       size: 35,
          //     ),
          //     margin: EdgeInsets.zero,
          //     snackStyle: SnackStyle.GROUNDED);
          print("no connction");
        } else {
          x = 1;
          print(" connction");
          Get.back();
          // if (Get.isSnackbarOpen) {
          //   Get.closeCurrentSnackbar();
          // }
        }
      });
      super.onInit();
    } catch (e) {
      print(e);
    }
  }
}
