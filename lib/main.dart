import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/screens/home_screen.dart';
import 'package:fake_taxi/screens/login_screen.dart';
import 'package:fake_taxi/screens/register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

DatabaseReference usersRef = FirebaseDatabase.instance.reference().child('users');

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppData() ,
      child: MaterialApp(
        title: 'Fake Taxi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: "Brand Bold",
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primarySwatch: Colors.blue,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null ? LoginScreen.idScreen : HomeScreen.idScreen,
        routes: {
          RegisterScreen.idScreen: (context ) => RegisterScreen(),
          LoginScreen.idScreen: (context ) => LoginScreen(),
          HomeScreen.idScreen: (context ) => HomeScreen(),
        },
      ),
    );
  }
}

