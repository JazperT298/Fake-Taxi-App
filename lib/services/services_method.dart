// ignore_for_file: await_only_futures

import 'package:fake_taxi/config_maps.dart';
import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/models/address.dart';
import 'package:fake_taxi/models/direct_detials.dart';
import 'package:fake_taxi/models/users.dart';
import 'package:fake_taxi/services/request_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class ServicesMethod {
  static Future<String> searchCoordinateAddress(Position position, context) async {
    String placeAddress = "";
    String st1, st2, st3, st4, st5;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestServices.getRequest(url);

    if (response != "failed") {
      //Full Address
      //placeAddress = response["results"][0]["formatted_address"];

      //Optional Address
      st1 = response["results"][0]["address_components"][0]["long_name"];
      st2 = response["results"][0]["address_components"][1]["long_name"];
      st3 = response["results"][0]["address_components"][2]["long_name"];
      st4 = response["results"][0]["address_components"][3]["long_name"];
      st5 = response["results"][0]["address_components"][4]["long_name"];
      placeAddress = st1 + ", " + st2 + ", " + ", " + st3 + ", " + st4 + ", " + st5;

      Address userPickUpAddress = new Address();
      userPickUpAddress.longtitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
    }
    return placeAddress;
  }

  static Future<DirectionDetails> getPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition) async {
    String directionUrl =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&key=$mapKey";

    var res = await RequestServices.getRequest(directionUrl);

    if (res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();
    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];
    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];
    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails directionDetails) {
    //in terms of USD
    double timeTraveledFare = (directionDetails.durationValue / 60) * 0.20;
    double distanceTraveledFare = (directionDetails.durationValue / 1000) * 0.20;

    double totalFareAmount = timeTraveledFare + distanceTraveledFare;

    //Local Currency
    //1$ = 50 PESO
    double totalLocalAmount = totalFareAmount * 50;

    return totalLocalAmount.truncate();
  }

  static void getCurrentOnlineUserInfo() async {
    firebaseUser = await FirebaseAuth.instance.currentUser;
    String userId = firebaseUser.uid;
    DatabaseReference reference = FirebaseDatabase.instance.reference().child("users").child(userId);

    reference.once().then((DataSnapshot dataSnapshot) {
      userCurrentInfo = Users.fromSnapshot(dataSnapshot);
    });
  }
}
