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

double starCounter = 0.0;
String title = "";
String carRideType = "";

String serverToken =
    "key=AAAAgyudES0:APA91bGZjOc3Dje2kxGTfvUicXFA8XaeOGB3WTpcp0DxBEOwondnXAVt-_koh_l_iJGeO6Czt2mEq8x65EvDuJIZ_LCqgY0hkWQ3bqU5mBjspjCMAdz_pQ8QBNyru3AFLuWIgq9op3cs";
