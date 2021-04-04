import 'package:fake_taxi/config_maps.dart';
import 'package:fake_taxi/services/request_services.dart';
import 'package:geolocator/geolocator.dart';

class ServicesMethod{
  static Future<String> searchCoordinateAddress(Position position) async {
    String placeAddress = "";
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    var response = await RequestServices.getRequest(url);

    if(response != "failed"){
      placeAddress = response["results"][0]["formatted_address"];
    }
    return placeAddress;
  }
}