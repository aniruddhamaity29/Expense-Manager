import 'dart:typed_data';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final double radius;
  final Uint8List? image;

  ProfileAvatar({required this.radius, this.image, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: image != null
          ? MemoryImage(image!)
          : const AssetImage('asset/images/profile.png') as ImageProvider,
    );
  }
}
