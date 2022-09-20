// ignore_for_file: unused_import, must_be_immutable

import 'package:fake_taxi/config_maps.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';

class ProfileTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   backgroundColor: Colors.white70,
    //   body: SafeArea(
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         Text(
    //           userCurrentInfo.name,
    //           style: TextStyle(
    //             fontSize: 65.0,
    //             color: Colors.white,
    //             fontWeight: FontWeight.bold,
    //             fontFamily: 'Signatra',
    //           ),
    //         ),
    //         SizedBox(
    //           height: 20,
    //           width: 200,
    //           child: Divider(
    //             color: Colors.white,
    //           ),
    //         ),
    //         SizedBox(
    //           height: 40.0,
    //         ),
    //         InfoCard(
    //           text: userCurrentInfo.phone,
    //           icon: Icons.phone,
    //           onPressed: () async {
    //             print("this is phone.");
    //           },
    //         ),
    //         InfoCard(
    //           text: userCurrentInfo.email,
    //           icon: Icons.email,
    //           onPressed: () async {
    //             print("this is email.");
    //           },
    //         ),
    //       ],
    //     ),
    //   ),
    // );
    return Scaffold(
      body: Material(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: SingleChildScrollView(
            child: IntrinsicWidth(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.black87,
                              Colors.black54,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 30.0,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          child: GestureDetector(
                            child: Container(
                              alignment: Alignment(0.0, 1.7),
                              child: CircleAvatar(
                                backgroundColor: Colors.grey,
                                radius: 60.0,
                                child: CircleAvatar(
                                  backgroundImage: AssetImage('assets/images/user_icon.png'),
                                  radius: 59.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  Center(
                    child: Text(
                      userCurrentInfo.name,
                      style: TextStyle(
                        fontSize: 32.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Signatra',
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 5,
                      bottom: 0,
                    ),
                    child: Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {},
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phone Number : ',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16, // theme.textTheme.subtitle1!.fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Brand-Regular'),
                              ),
                              Text(
                                userCurrentInfo.phone,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16, // theme.textTheme.subtitle1!.fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Brand-Regular'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 5,
                    thickness: 1,
                    indent: 25,
                    endIndent: 25,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24.0,
                      right: 24.0,
                      top: 5,
                      bottom: 0,
                    ),
                    child: Container(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {},
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Email : ',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16, // theme.textTheme.subtitle1!.fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Brand-Regular'),
                              ),
                              Text(
                                userCurrentInfo.email,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16, // theme.textTheme.subtitle1!.fontSize,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Brand-Regular'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 5,
                    thickness: 1,
                    indent: 25,
                    endIndent: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  Function onPressed;

  InfoCard({
    this.text,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Card(
        color: Colors.white,
        margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 25.0),
        child: ListTile(
          leading: Icon(
            icon,
            color: Colors.black87,
          ),
          title: Text(
            text,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16.0,
              fontFamily: 'Brand Bold',
            ),
          ),
        ),
      ),
    );
  }
}
