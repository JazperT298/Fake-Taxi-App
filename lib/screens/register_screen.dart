// ignore_for_file: must_be_immutable

import 'package:fake_taxi/main.dart';
import 'package:fake_taxi/screens/home_screen.dart';
import 'package:fake_taxi/screens/login_screen.dart';
import 'package:fake_taxi/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterScreen extends StatelessWidget {
  static const String idScreen = "register";

  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   // leading: Icon(Icons.ar),
      //   elevation: 0,
      //   leading: IconButton(
      //     color: Colors.black,
      //     icon: Icon(Icons.arrow_back_ios),
      //     iconSize: 20.0,
      //     onPressed: () {
      //       Navigator.pop(context);
      //     },
      //   ),
      //   centerTitle: true,
      // ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 45.0,
              ),
              Center(
                child: Image(
                  image: AssetImage(
                    "assets/images/logo.png",
                  ),
                  width: 200.0,
                  height: 180.0,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                'Signup as Passenger',
                style: TextStyle(
                  fontSize: 24.0,
                  fontFamily: "Brand Bold",
                ),
                textAlign: TextAlign.center,
              ),
              Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: nameTextEditingController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: "Name",
                        labelStyle: TextStyle(fontSize: 14.0),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(fontSize: 14.0),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: phoneTextEditingController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: "Phone",
                        labelStyle: TextStyle(fontSize: 14.0),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 1.0,
                    ),
                    TextField(
                      controller: passwordTextEditingController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Password",
                        labelStyle: TextStyle(fontSize: 14.0),
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    MaterialButton(
                      onPressed: () {
                        if (nameTextEditingController.text.isEmpty ||
                            emailTextEditingController.text.isEmpty ||
                            phoneTextEditingController.text.isEmpty ||
                            passwordTextEditingController.text.isEmpty) {
                          Fluttertoast.showToast(msg: "Fill up empty fields!");
                        } else if (nameTextEditingController.text.length < 4) {
                          Fluttertoast.showToast(msg: "Name must be atleast 3 Characters!");
                        } else if (!emailTextEditingController.text.contains("@") || !emailTextEditingController.text.contains(".com")) {
                          Fluttertoast.showToast(msg: "Email address is not valid!");
                        } else if (phoneTextEditingController.text.isEmpty) {
                          Fluttertoast.showToast(msg: "Phone number is mandatory");
                        } else if (passwordTextEditingController.text.length < 6) {
                          Fluttertoast.showToast(msg: "Password must be atleast 6 Characters!");
                        } else {
                          registerNewUser(context);
                        }
                      },
                      color: Colors.orange,
                      textColor: Colors.white,
                      child: Container(
                        height: 50,
                        child: Center(
                          child: Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: "Brand Bold",
                            ),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(24.0)),
                    ),
                  ],
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                child: Text(
                  'Already have an Account? Login here!',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void registerNewUser(BuildContext context) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return ProgressDialog(
            message: "Registering, Please wait...",
          );
        });
    final User user = (await firebaseAuth
            .createUserWithEmailAndPassword(email: emailTextEditingController.text, password: passwordTextEditingController.text)
            .catchError((errMsg) {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: " + errMsg.toString());
    }))
        .user;

    if (user != null) {
      usersRef.child(user.uid);

      Map userDataMap = {
        "name": nameTextEditingController.text.trim(),
        "email": emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
      };
      //Navigator.pop(context);
      usersRef.child(user.uid).set(userDataMap);
      Fluttertoast.showToast(msg: "New user account has been created!");

      Navigator.pushNamedAndRemoveUntil(context, HomeScreen.idScreen, (route) => false);
    } else {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "New user account has not been created!");
    }
  }
}
