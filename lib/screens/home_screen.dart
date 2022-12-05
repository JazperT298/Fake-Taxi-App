// ignore_for_file: deprecated_member_use, cancel_subscriptions, unused_local_variable, unused_import, unnecessary_brace_in_string_interps

import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:fake_taxi/config_maps.dart';
import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/main.dart';
import 'package:fake_taxi/models/direct_detials.dart';
import 'package:fake_taxi/models/nearby_available_drivers.dart';
import 'package:fake_taxi/screens/about_screen.dart';
import 'package:fake_taxi/screens/history_screen.dart';
import 'package:fake_taxi/screens/login_screen.dart';
import 'package:fake_taxi/screens/profile_tabpage.dart';
import 'package:fake_taxi/screens/rating_screen.dart';
import 'package:fake_taxi/screens/search_screen.dart';
import 'package:fake_taxi/services/geofire_services.dart';
import 'package:fake_taxi/services/services_method.dart';
import 'package:fake_taxi/widgets/collectfare_dialog.dart';
import 'package:fake_taxi/widgets/divider.dart';
import 'package:fake_taxi/widgets/nodriver_available_dialog.dart';
import 'package:fake_taxi/widgets/progress_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  static const String idScreen = "homeScreen";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 280.0;
  double requestRideContainerHeight = 0;
  double driverDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference rideRequestRef;

  BitmapDescriptor nearByIcon;

  List<NearbyAvailableDrivers> availableDrivers;

  String state = "normal";

  StreamSubscription<Event> rideStreamSubscription;

  bool isRequestingPositionDetails = false;

  String uName = "";
  var currentFormat;

  @override
  void initState() {
    super.initState();
    ServicesMethod.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef = FirebaseDatabase.instance.reference().child("Ride Requests").push();

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocationMap = {"latitude": pickUp.latitude.toString(), "longtitude": pickUp.longtitude.toString()};

    Map dropOffLocationMap = {"latitude": dropOff.latitude.toString(), "longtitude": dropOff.longtitude.toString()};

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment": "cash",
      "pickup": pickUpLocationMap,
      "dropoff": dropOffLocationMap,
      "create_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef.onValue.listen((event) async {
      if (event.snapshot.value == null) {
        return;
      }

      if (event.snapshot.value["car_details"] != null) {
        setState(() {
          carDetailsDriver = event.snapshot.value["car_details"].toString();
        });
      }
      if (event.snapshot.value["driver_name"] != null) {
        setState(() {
          driverName = event.snapshot.value["driver_name"].toString();
        });
      }
      if (event.snapshot.value["driver_phone"] != null) {
        setState(() {
          driverphone = event.snapshot.value["driver_phone"].toString();
        });
      }
      if (event.snapshot.value["imageUrl"] != null) {
        setState(() {
          driverImage = event.snapshot.value["imageUrl"].toString();
        });
      }

      if (event.snapshot.value["driver_location"] != null) {
        double driverLat = double.parse(event.snapshot.value["driver_location"]["latitude"].toString());
        double driverLng = double.parse(event.snapshot.value["driver_location"]["longitude"].toString());
        LatLng driverCurrentLocation = LatLng(driverLat, driverLng);

        if (statusRide == "accepted") {
          updateRideTimeToPickUpLoc(driverCurrentLocation);
        } else if (statusRide == "onride") {
          updateRideTimeToDropOffLoc(driverCurrentLocation);
        } else if (statusRide == "arrived") {
          setState(() {
            rideStatus = "Driver has Arrived.";
          });
        }
      }

      if (event.snapshot.value["status"] != null) {
        statusRide = event.snapshot.value["status"].toString();
      }
      if (statusRide == "accepted") {
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofileMarkers();
      }
      if (statusRide == "ended") {
        if (event.snapshot.value["fares"] != null) {
          int fare = int.parse(event.snapshot.value["fares"].toString());
          var res = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => CollectFareDialog(
              paymentMethod: "cash",
              fareAmount: fare,
            ),
          );

          String driverId = "";
          if (res == "close") {
            if (event.snapshot.value["driver_id"] != null) {
              driverId = event.snapshot.value["driver_id"].toString();
            }

            Navigator.of(context).push(MaterialPageRoute(builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    });
  }

  void deleteGeofileMarkers() {
    setState(() {
      markersSet.removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);
      var details = await ServicesMethod.getPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async {
    if (isRequestingPositionDetails == false) {
      isRequestingPositionDetails = true;

      var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff.latitude, dropOff.longtitude);

      var details = await ServicesMethod.getPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Going to Destination - " + details.durationText;
      });

      isRequestingPositionDetails = false;
    }
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
    setState(() {
      state = "normal";
    });
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 230.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingOfMap = 230;
      drawerOpen = false;
    });

    saveRideRequest();
  }

  void displayDriverDetailsContainer() {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 295.0;
      driverDetailsContainerHeight = 285.0;
    });
  }

  resetApp() {
    // setState(() {
    //   drawerOpen = true;
    //   searchContainerHeight = 280.0;
    //   rideDetailsContainerHeight = 0.0;
    //   requestRideContainerHeight = 0.0;
    //   bottomPaddingOfMap = 230;

    //   polylineSet.clear();
    //   markersSet.clear();
    //   circlesSet.clear();
    //   polylineCoordinates.clear();
    // });
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      polylineCoordinates.clear();

      statusRide = "";
      driverName = "";
      driverphone = "";
      driverImage = "";
      carDetailsDriver = "";
      rideStatus = "Driver is Coming";
      driverDetailsContainerHeight = 0.0;
    });
    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 280.0;
      bottomPaddingOfMap = 230;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address = await ServicesMethod.searchCoordinateAddress(position, context);
    print("This is your address " + address);

    initGeoFireListner();

    uName = userCurrentInfo.name;

    ServicesMethod.retrieveHistoryInfo(context);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(8.507651591446564, 124.6533884950392),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    Locale locale = Localizations.localeOf(context);
    currentFormat = NumberFormat.simpleCurrency(locale: locale.toString());
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              //Drawer Header
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uName,
                            style: TextStyle(fontSize: 16.0, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileTabPage()));
                              },
                              child: Text("Visit Profile")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              DividerWidget(),

              SizedBox(
                height: 12.0,
              ),

              //Drawer Body Contrllers
              ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
                },
                leading: Icon(Icons.history),
                title: Text(
                  "History",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileTabPage()));
                },
                leading: Icon(Icons.person),
                title: Text(
                  "Visit Profile",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen()));
              //   },
              //   child: ListTile(
              //     leading: Icon(Icons.info),
              //     title: Text(
              //       "About",
              //       style: TextStyle(fontSize: 15.0),
              //     ),
              //   ),
              // ),
              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                leading: Icon(Icons.logout),
                title: Text(
                  "Sign Out",
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap, top: 25.0),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 300.0;
              });

              locatePosition();
            },
          ),

          //HamburgerButton for Drawer
          Positioned(
            top: 36.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.0),
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
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    (drawerOpen) ? Icons.menu : Icons.close,
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          //Search Ui
          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(18.0), topRight: Radius.circular(18.0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 6.0),
                      Text(
                        // "Hi ${userCurrentInfo.name}!",
                        "Hi there!",
                        style: TextStyle(fontSize: 16.0),
                      ),
                      Text(
                        "Where to?",
                        style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),
                      ),
                      SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
                          print('res $res');
                          if (res == "obtainDirection") {
                            displayRideDetailsContainer();
                          } else {
                            displayRideDetailsContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black54,
                                blurRadius: 6.0,
                                spreadRadius: 0.5,
                                offset: Offset(0.7, 0.7),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text("Search Drop Off"),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24.0),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width / 1.30,
                                child: Text(
                                  Provider.of<AppData>(context).pickUpLocation != null
                                      ? Provider.of<AppData>(context).pickUpLocation.placeName
                                      : "Add Home",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your living home address",
                                style: TextStyle(color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10.0),
                      DividerWidget(),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your office address",
                                style: TextStyle(color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Ride Details Ui
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [
                      //Motorcycle ride
                      GestureDetector(
                        onTap: () {
                          displayToastMessage("Searching Multicab...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "Multicab";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireServices.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/images/multicab.png",
                                  height: 50.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Multicab",
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontFamily: "Brand Bold",
                                      ),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails.distanceText : ''),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? 'Php 10.00'
                                      : ''), //${(ServicesMethod.calculateFares(tripDirectionDetails))}' : ''),
                                  style: TextStyle(
                                    fontFamily: "Brand Bold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 10.0,
                      ),
                      Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),

                      //Motorela ride
                      GestureDetector(
                        onTap: () {
                          displayToastMessage("searching Motorela...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "Motorela";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireServices.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset(
                                  "assets/images/playstore.png",
                                  height: 50.0,
                                  width: 80.0,
                                ),
                                SizedBox(
                                  width: 16.0,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Motorela",
                                      style: TextStyle(
                                        fontSize: 18.0,
                                        fontFamily: "Brand Bold",
                                      ),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails.distanceText : ''),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? 'Php 10.00'
                                      : ''), //${ServicesMethod.calculateFares(tripDirectionDetails) / 3}' : ''),
                                  style: TextStyle(
                                    fontFamily: "Brand Bold",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 10.0,
                      ),
                      Divider(
                        height: 2.0,
                        thickness: 2.0,
                      ),
                      SizedBox(
                        height: 10.0,
                      ),

                      // Taxi ride=
                      // GestureDetector(
                      //   onTap: () {
                      //     displayToastMessage("searching Taxi...", context);

                      //     setState(() {
                      //       state = "requesting";
                      //       carRideType = "Taxi";
                      //     });
                      //     displayRequestRideContainer();
                      //     availableDrivers = GeoFireServices.nearByAvailableDriversList;
                      //     searchNearestDriver();
                      // },
                      // child: Container(
                      //   width: double.infinity,
                      //   child: Padding(
                      //     padding: EdgeInsets.symmetric(horizontal: 16.0),
                      //     child: Row(
                      //       children: [
                      //         Image.asset(
                      //           "assets/images/taxi.png",
                      //           height: 50.0,
                      //           width: 80.0,
                      //         ),
                      //         SizedBox(
                      //           width: 16.0,
                      //         ),
                      //         Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: [
                      //             Text(
                      //                 "Taxi",
                      //                 style: TextStyle(
                      //                   fontSize: 18.0,
                      //                   fontFamily: "Brand Bold",
                      //                 ),
                      //               ),
                      //               Text(
                      //                 ((tripDirectionDetails != null) ? tripDirectionDetails.distanceText : ''),
                      //                 style: TextStyle(
                      //                   fontSize: 16.0,
                      //                   color: Colors.grey,
                      //                 ),
                      //               ),
                      //             ],
                      //           ),
                      //           Expanded(child: Container()),
                      //           Text(
                      //             ((tripDirectionDetails != null) ? 'Php ${(ServicesMethod.calculateFares(tripDirectionDetails)) * 2}' : ''),
                      //             style: TextStyle(
                      //               fontFamily: "Brand Bold",
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      // SizedBox(
                      //   height: 10.0,
                      // ),
                      // Divider(
                      //   height: 2.0,
                      //   thickness: 2.0,
                      // ),
                      // SizedBox(
                      //   height: 10.0,
                      // ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.moneyCheckAlt,
                              size: 18.0,
                              color: Colors.black54,
                            ),
                            SizedBox(
                              width: 16.0,
                            ),
                            Text("Cash"),
                            SizedBox(
                              width: 6.0,
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.black54,
                              size: 16.0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Cancel Ui
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ColorizeAnimatedTextKit(
                        onTap: () {
                          print("Tap Event");
                        },
                        text: [
                          "Requesting a Ride...",
                          "Please wait...",
                          "Finding a Driver...",
                        ],
                        textStyle: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold), //fontFamily: "Signatra"),
                        colors: [
                          Colors.green,
                          Colors.purple,
                          Colors.pink,
                          Colors.blue,
                          Colors.yellow,
                          Colors.red,
                        ],
                        textAlign: TextAlign.center,
                        // textDirection: TextDirection.
                        // alignment: AlignmentDirectional.topStart // or Alignment.topLeft
                      ),
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0, color: Colors.grey[300]),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //Display Assisned Driver Info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 6.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          rideStatus,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Divider(
                      height: 2.0,
                      thickness: 2.0,
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Text(
                      carDetailsDriver,
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 20.0,
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(driverImage),
                            radius: 19.0,
                          ),
                        ),
                        SizedBox(
                          width: 8.0,
                        ),
                        Text(
                          driverName,
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 8.0,
                    ),
                    Divider(
                      height: 2.0,
                      thickness: 2.0,
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //call button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: RaisedButton(
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(24.0),
                            ),
                            onPressed: () async {
                              launch(('tel://${driverphone}'));
                            },
                            color: Colors.black87,
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Call Driver   ",
                                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.call,
                                    color: Colors.white,
                                    size: 26.0,
                                  ),
                                ],
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
          ),
        ],
      ),
    );
    // return Scaffold(
    //   key: scaffoldKey,
    //   // appBar: AppBar(
    //   //   title: Text(
    //   //     'Home Screen',
    //   //   ),
    //   // ),
    //   drawer: Container(
    //     color: Colors.white,
    //     width: 255.0,
    //     child: Drawer(
    //       child: ListView(
    //         children: [
    //           //Drawer Header
    //           Container(
    //             height: 165.0,
    //             child: DrawerHeader(
    //               decoration: BoxDecoration(
    //                 color: Colors.white,
    //               ),
    //               child: Row(
    //                 children: [
    //                   Image.asset(
    //                     "assets/assets/images/user_icon.png",
    //                     height: 65.0,
    //                     width: 65.0,
    //                   ),
    //                   SizedBox(
    //                     height: 16.0,
    //                   ),
    //                   Column(
    //                     mainAxisAlignment: MainAxisAlignment.center,
    //                     children: [
    //                       Text(
    //                         'Profile name',
    //                         style: TextStyle(fontSize: 16.0, fontFamily: "Brand bold"),
    //                       ),
    //                       SizedBox(
    //                         height: 6.0,
    //                       ),
    //                       Text(
    //                         'Visit Profile',
    //                       ),
    //                     ],
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ),
    //           DividerWidget(),
    //           SizedBox(
    //             height: 12.0,
    //           ),
    //           //Drawer Body
    //           ListTile(
    //             leading: Icon(
    //               Icons.history,
    //             ),
    //             title: Text(
    //               'History',
    //               style: TextStyle(
    //                 fontSize: 15.0,
    //               ),
    //             ),
    //           ),
    //           ListTile(
    //             leading: Icon(
    //               Icons.person,
    //             ),
    //             title: Text(
    //               'Visit Profile',
    //               style: TextStyle(
    //                 fontSize: 15.0,
    //               ),
    //             ),
    //           ),
    //           ListTile(
    //             leading: Icon(
    //               Icons.info,
    //             ),
    //             title: Text(
    //               'About',
    //               style: TextStyle(
    //                 fontSize: 15.0,
    //               ),
    //             ),
    //           ),
    //           InkWell(
    //             onTap: () {
    //               FirebaseAuth.instance.signOut();
    //               Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
    //             },
    //             child: ListTile(
    //               leading: Icon(
    //                 Icons.logout,
    //               ),
    //               title: Text(
    //                 'Logout',
    //                 style: TextStyle(
    //                   fontSize: 15.0,
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    //   body: SafeArea(
    //     child: Stack(
    //       children: [
    //         GoogleMap(
    //           padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
    //           initialCameraPosition: _kGooglePlex,
    //           mapType: MapType.normal,
    //           myLocationEnabled: true,
    //           zoomGesturesEnabled: true,
    //           zoomControlsEnabled: true,
    //           polylines: polylineSet,
    //           markers: markersSet,
    //           circles: circlesSet,
    //           onMapCreated: (GoogleMapController controller) {
    //             _controller.complete(controller);
    //             newGoogleMapController = controller;
    //             setState(() {
    //               bottomPaddingOfMap = 280.0;
    //             });

    //             locatePosition();
    //           },
    //         ),
    //         //Hamburger button for drawer
    //         Positioned(
    //           top: 15.0,
    //           left: 22.0,
    //           child: GestureDetector(
    //             onTap: () {
    //               if (drawerOpen) {
    //                 scaffoldKey.currentState.openDrawer();
    //               } else {
    //                 resetApp();
    //               }
    //             },
    //             child: Container(
    //               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22.0), boxShadow: [
    //                 BoxShadow(
    //                   color: Colors.black,
    //                   blurRadius: 6.0,
    //                   spreadRadius: 0.5,
    //                   offset: Offset(
    //                     0.7,
    //                     0.7,
    //                   ),
    //                 ),
    //               ]),
    //               child: CircleAvatar(
    //                 backgroundColor: Colors.white,
    //                 child: Icon(
    //                   drawerOpen ? Icons.menu : Icons.close,
    //                   color: Colors.black,
    //                 ),
    //                 radius: 20.0,
    //               ),
    //             ),
    //           ),
    //         ),
    //         Positioned(
    //           left: 0.0,
    //           right: 0.0,
    //           bottom: 0.0,
    //           child: AnimatedSize(
    //             vsync: this,
    //             curve: Curves.bounceIn,
    //             duration: new Duration(milliseconds: 160),
    //             child: Container(
    //               height: searchContainerHeight,
    //               decoration: BoxDecoration(
    //                   color: Colors.white,
    //                   borderRadius: BorderRadius.only(
    //                     topLeft: Radius.circular(18.0),
    //                     topRight: Radius.circular(18.0),
    //                   ),
    //                   boxShadow: [
    //                     BoxShadow(
    //                       color: Colors.black,
    //                       blurRadius: 16.0,
    //                       spreadRadius: 0.5,
    //                       offset: Offset(0.7, 0.7),
    //                     ),
    //                   ]),
    //               child: Padding(
    //                 padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
    //                 child: Column(
    //                   crossAxisAlignment: CrossAxisAlignment.start,
    //                   children: [
    //                     SizedBox(
    //                       height: 6.0,
    //                     ),
    //                     Text(
    //                       'Hi there',
    //                       style: TextStyle(
    //                         fontSize: 14.0,
    //                       ),
    //                     ),
    //                     Text(
    //                       'Where to?',
    //                       style: TextStyle(fontSize: 20.0, fontFamily: "Brand bold"),
    //                     ),
    //                     SizedBox(
    //                       height: 20.0,
    //                     ),
    //                     GestureDetector(
    //                       onTap: () async {
    //                         var res = await Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
    //                         if (res == "getDirection") {
    //                           displayRideDetailsContainer();
    //                           //await getPlaceDirection();
    //                         }
    //                       },
    //                       child: Container(
    //                         decoration: BoxDecoration(
    //                             color: Colors.white,
    //                             borderRadius: BorderRadius.circular(
    //                               5.0,
    //                             ),
    //                             boxShadow: [
    //                               BoxShadow(
    //                                 color: Colors.black54,
    //                                 blurRadius: 6.0,
    //                                 spreadRadius: 0.5,
    //                                 offset: Offset(0.7, 0.7),
    //                               ),
    //                             ]),
    //                         child: Padding(
    //                           padding: EdgeInsets.all(12.0),
    //                           child: Row(
    //                             children: [
    //                               Icon(
    //                                 Icons.search,
    //                                 color: Colors.blueAccent,
    //                               ),
    //                               SizedBox(
    //                                 width: 10.0,
    //                               ),
    //                               Text("Search Drop Off"),
    //                             ],
    //                           ),
    //                         ),
    //                       ),
    //                     ),
    //                     SizedBox(
    //                       height: 20.0,
    //                     ),
    //                     Row(
    //                       children: [
    //                         Icon(
    //                           Icons.home,
    //                           color: Colors.grey,
    //                         ),
    //                         SizedBox(
    //                           width: 12.0,
    //                         ),
    //                         Column(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             Container(
    //                               // margin: EdgeInsets.only(right: 13.0),
    //                               width: MediaQuery.of(context).size.width / 1.30,
    //                               child: Text(
    //                                 Provider.of<AppData>(context).pickUpLocation != null
    //                                     ? Provider.of<AppData>(context).pickUpLocation.placeName
    //                                     : "Add Home",
    //                                 overflow: TextOverflow.ellipsis,
    //                               ),
    //                             ),
    //                             SizedBox(
    //                               height: 4.0,
    //                             ),
    //                             Text(
    //                               'Your living home address',
    //                               style: TextStyle(
    //                                 color: Colors.black54,
    //                                 fontSize: 14.0,
    //                               ),
    //                             )
    //                           ],
    //                         )
    //                       ],
    //                     ),
    //                     SizedBox(
    //                       height: 10.0,
    //                     ),
    //                     DividerWidget(),
    //                     SizedBox(
    //                       height: 16.0,
    //                     ),
    //                     Row(
    //                       children: [
    //                         Icon(
    //                           Icons.work,
    //                           color: Colors.grey,
    //                         ),
    //                         SizedBox(
    //                           width: 12.0,
    //                         ),
    //                         Column(
    //                           crossAxisAlignment: CrossAxisAlignment.start,
    //                           children: [
    //                             Container(
    //                               width: MediaQuery.of(context).size.width / 1.30,
    //                               child: Text(
    //                                 "Add Work",
    //                                 overflow: TextOverflow.ellipsis,
    //                               ),
    //                             ),
    //                             SizedBox(
    //                               height: 4.0,
    //                             ),
    //                             Text(
    //                               'Your office address',
    //                               style: TextStyle(
    //                                 color: Colors.black54,
    //                                 fontSize: 14.0,
    //                               ),
    //                             )
    //                           ],
    //                         )
    //                       ],
    //                     ),
    //                   ],
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ),
    //         Positioned(
    //           bottom: 0.0,
    //           left: 0.0,
    //           right: 0.0,
    //           child: AnimatedSize(
    //             vsync: this,
    //             curve: Curves.bounceIn,
    //             duration: new Duration(milliseconds: 160),
    //             child: Container(
    //               height: rideDetailsContainerHeight,
    //               decoration: BoxDecoration(
    //                   color: Colors.white,
    //                   borderRadius: BorderRadius.only(
    //                     topLeft: Radius.circular(16.0),
    //                     topRight: Radius.circular(16.0),
    //                   ),
    //                   boxShadow: [
    //                     BoxShadow(
    //                       color: Colors.black,
    //                       blurRadius: 16.0,
    //                       spreadRadius: 0.5,
    //                       offset: Offset(
    //                         0.7,
    //                         0.7,
    //                       ),
    //                     ),
    //                   ]),
    //               child: Padding(
    //                 padding: EdgeInsets.symmetric(
    //                   vertical: 17.0,
    //                 ),
    //                 child: Column(
    //                   children: [
    //                     Container(
    //                       width: double.infinity,
    //                       color: Colors.tealAccent[100],
    //                       child: Padding(
    //                         padding: EdgeInsets.symmetric(horizontal: 16.0),
    //                         child: Row(
    //                           children: [
    //                             Image.asset(
    //                               "assets/assets/images/taxi.png",
    //                               height: 70.0,
    //                               width: 80.0,
    //                             ),
    //                             SizedBox(
    //                               width: 16.0,
    //                             ),
    //                             Column(
    //                               crossAxisAlignment: CrossAxisAlignment.start,
    //                               children: [
    //                                 Text(
    //                                   'Car',
    //                                   style: TextStyle(
    //                                     fontSize: 18.0,
    //                                     fontFamily: "Brand bold",
    //                                   ),
    //                                 ),
    //                                 Text(
    //                                   ((tripDirectionDetails != null ? tripDirectionDetails.distanceText : '')),
    //                                   style: TextStyle(
    //                                     fontSize: 16.0,
    //                                     fontFamily: "Brand bold",
    //                                   ),
    //                                 ),
    //                               ],
    //                             ),
    //                             Expanded(
    //                               child: Container(),
    //                             ),
    //                             Text(
    //                               ((tripDirectionDetails != null ? '\₱ ' + '${ServicesMethod.calculateFares(tripDirectionDetails)}' : '')),
    //                               style: TextStyle(
    //                                 fontFamily: "Brand bold",
    //                               ),
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                     ),
    //                     SizedBox(
    //                       height: 20.0,
    //                     ),
    //                     Padding(
    //                       padding: EdgeInsets.symmetric(horizontal: 20.0),
    //                       child: Row(
    //                         children: [
    //                           Icon(
    //                             FontAwesomeIcons.moneyCheckAlt,
    //                             size: 18.0,
    //                             color: Colors.black54,
    //                           ),
    //                           SizedBox(
    //                             width: 16.0,
    //                           ),
    //                           Text(
    //                             'Cash',
    //                           ),
    //                           SizedBox(
    //                             width: 6.0,
    //                           ),
    //                           Icon(
    //                             Icons.keyboard_arrow_down,
    //                             color: Colors.black54,
    //                             size: 16.0,
    //                           ),
    //                         ],
    //                       ),
    //                     ),
    //                     SizedBox(
    //                       height: 24.0,
    //                     ),
    //                     Padding(
    //                       padding: EdgeInsets.symmetric(horizontal: 16.0),
    //                       child: MaterialButton(
    //                         onPressed: () {
    //                           displayRequestRideContainer();
    //                         },
    //                         color: Theme.of(context).accentColor,
    //                         child: Padding(
    //                           padding: EdgeInsets.all(17.0),
    //                           child: Row(
    //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                             children: [
    //                               Text(
    //                                 'Request',
    //                                 style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),
    //                               ),
    //                               Icon(
    //                                 FontAwesomeIcons.taxi,
    //                                 color: Colors.white,
    //                                 size: 26.0,
    //                               )
    //                             ],
    //                           ),
    //                         ),
    //                       ),
    //                     )
    //                   ],
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ),
    //         Positioned(
    //           bottom: 0.0,
    //           left: 0.0,
    //           right: 0.0,
    //           child: Container(
    //             decoration: BoxDecoration(
    //                 borderRadius: BorderRadius.only(
    //                   topLeft: Radius.circular(16.0),
    //                   topRight: Radius.circular(16.0),
    //                 ),
    //                 color: Colors.white,
    //                 boxShadow: [
    //                   BoxShadow(
    //                     spreadRadius: 0.5,
    //                     blurRadius: 16.0,
    //                     color: Colors.black54,
    //                     offset: Offset(0.7, 0.7),
    //                   )
    //                 ]),
    //             height: requestRideContainerHeight,
    //             child: Padding(
    //               padding: EdgeInsets.all(10.0),
    //               child: Column(
    //                 children: [
    //                   SizedBox(
    //                     height: 18.0,
    //                   ),
    //                   SizedBox(
    //                     width: double.infinity,
    //                     child: AnimatedTextKit(
    //                       animatedTexts: [
    //                         ColorizeAnimatedText(
    //                           'Requesting a Ride...',
    //                           textAlign: TextAlign.center,
    //                           textStyle: TextStyle(
    //                             fontSize: 30.0,
    //                             fontFamily: 'Brand Bold',
    //                           ),
    //                           colors: [
    //                             Colors.purple,
    //                             Colors.blue,
    //                             Colors.yellow,
    //                             Colors.red,
    //                           ],
    //                         ),
    //                         ColorizeAnimatedText(
    //                           'Please wait...',
    //                           textAlign: TextAlign.center,
    //                           textStyle: TextStyle(
    //                             fontSize: 30.0,
    //                             fontFamily: 'Brand Bold',
    //                           ),
    //                           colors: [
    //                             Colors.purple,
    //                             Colors.blue,
    //                             Colors.yellow,
    //                             Colors.red,
    //                           ],
    //                         ),
    //                         ColorizeAnimatedText(
    //                           'Finding a Driver...',
    //                           textAlign: TextAlign.center,
    //                           textStyle: TextStyle(
    //                             fontSize: 30.0,
    //                             fontFamily: 'Brand Bold',
    //                           ),
    //                           colors: [
    //                             Colors.purple,
    //                             Colors.blue,
    //                             Colors.yellow,
    //                             Colors.red,
    //                           ],
    //                         ),
    //                       ],
    //                       isRepeatingAnimation: true,
    //                       onTap: () {
    //                         print("Tap Event");
    //                       },
    //                     ),
    //                   ),
    //                   SizedBox(
    //                     height: 18.0,
    //                   ),
    //                   InkWell(
    //                     onTap: () {
    //                       cancelRideRequest();
    //                       resetApp();
    //                     },
    //                     child: Container(
    //                       height: 50.0,
    //                       width: 50.0,
    //                       decoration: BoxDecoration(
    //                         color: Colors.white,
    //                         borderRadius: BorderRadius.circular(26.0),
    //                         border: Border.all(width: 1, color: Colors.black54),
    //                       ),
    //                       child: Icon(
    //                         Icons.close,
    //                         size: 26.0,
    //                       ),
    //                     ),
    //                   ),
    //                   SizedBox(
    //                     height: 10.0,
    //                   ),
    //                   Container(
    //                     width: double.infinity,
    //                     child: Text(
    //                       'Cancel Ride',
    //                       textAlign: TextAlign.center,
    //                       style: TextStyle(
    //                         fontSize: 16.0,
    //                         fontWeight: FontWeight.bold,
    //                       ),
    //                     ),
    //                   )
    //                 ],
    //               ),
    //             ),
    //           ),
    //         )
    //       ],
    //     ),
    //   ),
    // );
  }

  Future<void> getPlaceDirection() async {
    var initialPos = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickupLatLng = LatLng(initialPos.latitude, initialPos.longtitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longtitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));

    var details = await ServicesMethod.getPlaceDirectionDetails(pickupLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });

    Navigator.pop(context);
    print("This is encoded points");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult = polylinePoints.decodePolyline(details.encodedPoints);

    polylineCoordinates.clear();
    if (decodePolylinePointsResult.isNotEmpty) {
      decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
        polylineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.red,
        polylineId: PolylineId("PolylineId"),
        jointType: JointType.round,
        points: polylineCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );
      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickupLatLng.latitude > dropOffLatLng.latitude && pickupLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.latitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickupLatLng.longitude), northeast: LatLng(pickupLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds = LatLngBounds(southwest: pickupLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickupLocationMaker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: initialPos.placeName,
        snippet: "My Location",
      ),
      position: pickupLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocationMaker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: finalPos.placeName,
        snippet: "Drop off Location",
      ),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickupLocationMaker);
      markersSet.add(dropOffLocationMaker);
    });

    Circle pickUpCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickupLatLng,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("blueAccent"),
    );

    Circle dropOffCircle = Circle(
      fillColor: Colors.purpleAccent,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.purpleAccent,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpCircle);
      circlesSet.add(dropOffCircle);
    });
  }

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");
    //comment
    Geofire.queryAtLocation(currentPosition.latitude, currentPosition.longitude, 15).listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireServices.nearByAvailableDriversList.add(nearbyAvailableDrivers);
            if (nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireServices.removeDriverFromList(map['key']);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers = NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map['key'];
            nearbyAvailableDrivers.latitude = map['latitude'];
            nearbyAvailableDrivers.longitude = map['longitude'];
            GeoFireServices.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
            updateAvailableDriversOnMap();
            break;
        }
      }

      setState(() {});
    });
    //comment
  }

  void updateAvailableDriversOnMap() {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();
    for (NearbyAvailableDrivers driver in GeoFireServices.nearByAvailableDriversList) {
      LatLng driverAvaiablePosition = LatLng(driver.latitude, driver.longitude);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvaiablePosition,
        icon: nearByIcon,
        //rotation: AssistantMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }
    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker() {
    if (nearByIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(30, 30));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "assets/images/pickicon.png").then((value) {
        nearByIcon = value;
      });
    }
  }

  void noDriverFound() {
    showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => NoDriverAvailableDialog());
  }

  void searchNearestDriver() {
    if (availableDrivers.length == 0) {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers[0];

    driversRef.child(driver.key).child("car_details").child("type").once().then((DataSnapshot snap) async {
      if (await snap.value != null) {
        String carType = snap.value.toString();
        if (carType == carRideType) {
          notifyDriver(driver);
          availableDrivers.removeAt(0);
        } else {
          displayToastMessage(carRideType + " Drivers not available. Try again.", context);
        }
      } else {
        displayToastMessage("No car found. Try again.", context);
      }
    });
  }

  void notifyDriver(NearbyAvailableDrivers driver) {
    driversRef.child(driver.key).child("newRide").set(rideRequestRef.key);

    driversRef.child(driver.key).child("token").once().then((DataSnapshot snap) {
      if (snap.value != null) {
        String token = snap.value.toString();
        ServicesMethod.sendNotificationToDriver(token, context, rideRequestRef.key);
      } else {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if (state != "requesting") {
          driversRef.child(driver.key).child("newRide").set("cancelled");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }

        driverRequestTimeOut = driverRequestTimeOut - 1;

        driversRef.child(driver.key).child("newRide").onValue.listen((event) {
          if (event.snapshot.value.toString() == "accepted") {
            driversRef.child(driver.key).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        if (driverRequestTimeOut == 0) {
          driversRef.child(driver.key).child("newRide").set("timeout");
          driversRef.child(driver.key).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }
      });
    });
  }
}

displayToastMessage(String message, BuildContext context) {
  Fluttertoast.showToast(msg: message);
}
