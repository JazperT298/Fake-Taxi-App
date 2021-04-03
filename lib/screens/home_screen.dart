import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home Screen',
        ),
      ),
    );
  }
}
