import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/daily.dart';
import 'package:flutter_application_1/pages/monthly.dart';
import 'package:flutter_application_1/pages/yearly.dart';
import 'package:flutter_application_1/utils/dimensions.dart';

class Tabbar extends StatefulWidget {
  const Tabbar({super.key});

  @override
  State<Tabbar> createState() => _TabbarState();
}

class _TabbarState extends State<Tabbar> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: DefaultTabController(
        length: 3, // Set the length to 3 for three tabs
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(
              'Expense Manager',
              style: TextStyle(
                color: Colors.black,
                fontSize: Dimensions.font24,
                fontFamily: 'Courier New',
              ),
            ),
            bottom: const TabBar(
              labelColor: Colors.white,
              tabs: [
                Tab(text: "Daily"),
                Tab(text: "Monthly"),
                Tab(text: "Yearly"),
              ],
            ),
            backgroundColor: Colors.purple[200],
            elevation: 0,
          ),
          body: const TabBarView(
            children: [
              Daily(),
              Monthly(),
              Yearly(),
            ],
          ),
        ),
      ),
    );
  }
}
