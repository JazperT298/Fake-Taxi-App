import 'package:fake_taxi/screens/home_screen.dart';
import 'package:flutter/material.dart';

class AboutScreen extends StatefulWidget {
  static const String idScreen = "about";

  @override
  _MyAboutScreenState createState() => _MyAboutScreenState();
}

class _MyAboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: ListView(
          children: <Widget>[
            Container(
              height: 220,
              child: Center(
                child: Image.asset('assets/images/uberx.png'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 30, left: 24, right: 24),
              child: Column(
                children: <Widget>[
                  Text(
                    'Uber  Clone',
                    style: TextStyle(fontSize: 90, fontFamily: 'Signatra'),
                  ),
                  SizedBox(height: 30),
                  Text(
                    'This app has been developed by Tony Atillo, '
                    'Co-founder of Coding Cafe. This app offer cheap rides at cheap rates, '
                    'and that\'s why 10M+ people already use this app',
                    style: TextStyle(fontFamily: "Brand-Bold"),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 40),
            // ignore: deprecated_member_use
            FlatButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, HomeScreen.idScreen, (route) => false);
                },
                child: const Text('Go Back', style: TextStyle(fontSize: 18, color: Colors.black)),
                shape: RoundedRectangleBorder(borderRadius: new BorderRadius.circular(10.0))),
          ],
        ));
  }
}
