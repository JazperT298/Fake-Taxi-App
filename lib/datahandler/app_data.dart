import 'package:fake_taxi/models/address.dart';
import 'package:flutter/cupertino.dart';

class AppData extends ChangeNotifier{

  Address pickUpLocation;

  void updatePickUpLocationAddress(Address pickUpAddress){
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

}