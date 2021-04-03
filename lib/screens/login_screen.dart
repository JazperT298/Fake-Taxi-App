import 'package:fake_taxi/main.dart';
import 'package:fake_taxi/screens/home_screen.dart';
import 'package:fake_taxi/screens/register_screen.dart';
import 'package:fake_taxi/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginScreen extends StatelessWidget {
  static const String idScreen = "login";

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                  width: 300.0,
                  height: 300.0,
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Text(
                'Login as Rider',
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
                      controller: emailTextEditingController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email",
                        labelStyle: TextStyle(fontSize: 14.0),
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
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
                        hintStyle:
                            TextStyle(color: Colors.grey, fontSize: 10.0),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                    SizedBox(
                      height: 30.0,
                    ),
                    MaterialButton(
                      onPressed: () {
                        if (!emailTextEditingController.text.contains("@") ||
                            !emailTextEditingController.text.contains(".com")) {
                          Fluttertoast.showToast(
                              msg: "Email address is not valid!");
                        } else if (passwordTextEditingController.text.isEmpty) {
                          Fluttertoast.showToast(
                              msg: "Password is not valid!");
                        }else {
                          loginAndAuthenticateUser(context);
                        }
                      },
                      color: Colors.yellow,
                      textColor: Colors.white,
                      child: Container(
                        height: 50,
                        child: Center(
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18.0,
                              fontFamily: "Brand Bold",
                            ),
                          ),
                        ),
                      ),
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(24.0)),
                    ),
                  ],
                ),
              ),
              MaterialButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, RegisterScreen.idScreen, (route) => false);
                },
                child: Text(
                  'Do not have an Account? Register here!',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void loginAndAuthenticateUser(BuildContext context) async {

    showDialog(context: context, barrierDismissible: false, builder: (context) {
      return ProgressDialog(message: "Authenticating, Please wait...",);
    });
    final User user = (await firebaseAuth
            .signInWithEmailAndPassword(
                email: emailTextEditingController.text,
                password: passwordTextEditingController.text)
            .catchError((errMsg) {
              Navigator.pop(context);
      Fluttertoast.showToast(msg: "Error: " + errMsg.toString());
    }))
        .user;

    if (user != null) {
      usersRef.child(user.uid).once().then((DataSnapshot snap) {
            if (snap.value != null) {
              Fluttertoast.showToast(msg: "Successfully login!");

              Navigator.pushNamedAndRemoveUntil(
                  context, HomeScreen.idScreen, (route) => false);
            } else {
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Invalid credentials");
            }
          });
    } else {
      Navigator.pop(context);
      Fluttertoast.showToast(msg: "An error occurred, cannot sign in!");
    }
  }
}
