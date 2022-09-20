import 'package:fake_taxi/config_maps.dart';
import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/models/address.dart';
import 'package:fake_taxi/models/place_predictions.dart';
import 'package:fake_taxi/services/request_services.dart';
import 'package:fake_taxi/widgets/divider.dart';
import 'package:fake_taxi/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController pickupTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  List<PlacePredictions> placePredictionList = [];
  @override
  Widget build(BuildContext context) {
    String placeAddress = Provider.of<AppData>(context, listen: false).pickUpLocation.placeName ?? "";
    pickupTextEditingController.text = placeAddress;

    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Container(
                height: 175.0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 6.0,
                      spreadRadius: 0.5,
                      offset: Offset(
                        0.7,
                        0.7,
                      ),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 25.0,
                    top: 20.0,
                    right: 25.0,
                    bottom: 20.0,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 5.0,
                      ),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(
                              Icons.arrow_back,
                            ),
                          ),
                          Center(
                            child: Text(
                              'Set Drop Off',
                              style: TextStyle(
                                fontSize: 18.0,
                                fontFamily: "Brand bold",
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/pickicon.png",
                            height: 16.0,
                            width: 16.0,
                          ),
                          SizedBox(
                            width: 18.0,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3.0),
                                child: TextField(
                                  controller: pickupTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Pickup Location",
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/desticon.png",
                            height: 16.0,
                            width: 16.0,
                          ),
                          SizedBox(
                            width: 18.0,
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(3.0),
                                child: TextField(
                                  onChanged: (val) {
                                    findPlace(dropOffTextEditingController.text);
                                  },
                                  controller: dropOffTextEditingController,
                                  decoration: InputDecoration(
                                    hintText: "Where to?",
                                    fillColor: Colors.grey[400],
                                    filled: true,
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              //Tile for prediction

              (placePredictionList.length > 0)
                  ? Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListView.separated(
                          padding: EdgeInsets.all(0.0),
                          separatorBuilder: (BuildContext context, int index) => DividerWidget(),
                          itemCount: placePredictionList.length,
                          itemBuilder: (context, index) {
                            return PredictionTile(
                              placePredictions: placePredictionList[index],
                            );
                          },
                          shrinkWrap: true,
                          physics: ClampingScrollPhysics(),
                        ),
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoComplete =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:PH";

      var res = await RequestServices.getRequest(autoComplete);

      if (res == "failed") {
        return;
      }
      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        print(predictions);
        var placesList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();

        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions placePredictions;
  PredictionTile({Key key, this.placePredictions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {
        getPlaceAddressDetails(placePredictions.placeId, context);
      },
      child: Container(
        margin: EdgeInsets.only(left: 0, top: 15),
        height: 50.0,
        child: Column(
          children: [
            // SizedBox(
            //   width: 10.0,
            // ),
            Row(
              children: [
                Icon(
                  Icons.add_location,
                ),
                SizedBox(
                  width: 14.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placePredictions.mainText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.0,
                        ),
                      ),
                      SizedBox(
                        height: 3.0,
                      ),
                      Text(
                        placePredictions.secondaryText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              ],
            ),
            // SizedBox(
            //   width: 10.0,
            // ),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String placeId, context) async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Setting Dropoff, Please wait",
            ));
    String placeDetailsUrl = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey";

    var res = await RequestServices.getRequest(placeDetailsUrl);
    Navigator.pop(context);
    if (res == "failed") {
      return;
    }
    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longtitude = res["result"]["geometry"]["location"]["lng"];

      Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(address);
      print("This is drop off ${address.placeName}");

      Navigator.pop(context, "getDirection");
    }
  }
}
