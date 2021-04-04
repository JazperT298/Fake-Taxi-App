import 'package:fake_taxi/config_maps.dart';
import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/models/address.dart';
import 'package:fake_taxi/services/request_services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ServicesMethod{
  static Future<String> searchCoordinateAddress(Position position, context) async {
    String placeAddress = "";
    String st1, st2,st3,st4,st5;
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestServices.getRequest(url);

    if(response != "failed"){
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
}