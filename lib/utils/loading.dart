import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:lottie/lottie.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CupertinoActivityIndicator(
              //   radius: 20,
              //   color: CupertinoColors.black,
              // )
              // CircularProgressIndicator(
              //   color: Colors.purple[300],
              // ),
              Lottie.asset('asset/animation/loading.json',
                  width: Dimensions.screenWidth),
            ],
          ),
        ),
      ),
    );
  }
}
