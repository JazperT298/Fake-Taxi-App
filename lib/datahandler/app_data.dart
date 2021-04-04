import 'package:fake_taxi/models/address.dart';
import 'package:flutter/cupertino.dart';

class AppData extends ChangeNotifier{

  Address pickUpLocation, dropOffLocation;

  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOff){
    dropOffLocation = dropOff;
    notifyListeners();
  }

}