import 'package:fake_taxi/models/users.dart';
import 'package:firebase_auth/firebase_auth.dart';

String mapKey = "AIzaSyBHekMm3Io_ftJUd-FGapD5nqGCffbPcAw";

User firebaseUser;
Users userCurrentInfo;

int driverRequestTimeOut = 40;
String statusRide = "";
String rideStatus = "Driver is Coming";
String carDetailsDriver = "";
String driverName = "";
String driverphone = "";
String driverImage = "";

double starCounter = 0.0;
String title = "";
String carRideType = "";

String serverToken =
    "key=AAAAocy8t8A:APA91bE7InvRTHqWFoz6c37iSjkVZldrgMvuSKGaYpi7H98WazobqCC4sHLzDUSSBdf9DUdkNiPdHPIbhuHQdxyMx-hYI98QAFl8cLsudZ2XMgMYKLTXGKtqWSHuym2d4RNxNY4Ps0Mu";
