import 'dart:async';

import 'package:fake_taxi/datahandler/app_data.dart';
import 'package:fake_taxi/screens/search_screen.dart';
import 'package:fake_taxi/services/services_method.dart';
import 'package:fake_taxi/widgets/divider.dart';
import 'package:fake_taxi/widgets/progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin{
  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 280.0;

  void displayRideDetailsContainer() async {
    await getPlaceDirection();

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainerHeight = 230.0;
      bottomPaddingOfMap = 230;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLngPosition, zoom: 15);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await ServicesMethod.searchCoordinateAddress(position, context);
    print("This is your address " + address);
  }

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(8.507651591446564, 124.6533884950392),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          'Home Screen',
        ),
      ),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(
                        height: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Profile name',
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text(
                            'Visit Profile',
                          ),
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
              //Drawer Body
              ListTile(
                leading: Icon(
                  Icons.history,
                ),
                title: Text(
                  'History',
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.person,
                ),
                title: Text(
                  'Visit Profile',
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.info,
                ),
                title: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            initialCameraPosition: _kGooglePlex,
            mapType: MapType.normal,
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
                bottomPaddingOfMap = 280.0;
              });

              locatePosition();
            },
          ),
          //Hamburger button for drawer
          Positioned(
            top: 45.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                scaffoldKey.currentState.openDrawer();
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
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.menu,
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),
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
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(18.0),
                      topRight: Radius.circular(18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 6.0,
                      ),
                      Text(
                        'Hi there',
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        'Where to?',
                        style:
                            TextStyle(fontSize: 20.0, fontFamily: "Brand bold"),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      GestureDetector(
                        onTap: () async {
                          var res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SearchScreen()));
                          if (res == "getDirection") {
                            displayRideDetailsContainer();
                            //await getPlaceDirection();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                5.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                ),
                              ]),
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
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
                      SizedBox(
                        height: 20.0,
                      ),
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
                                // margin: EdgeInsets.only(right: 13.0),
                                width: MediaQuery.of(context).size.width / 1.30,
                                child: Text(
                                  Provider.of<AppData>(context).pickUpLocation !=
                                          null
                                      ? Provider.of<AppData>(context)
                                          .pickUpLocation
                                          .placeName
                                      : "Add Home",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                'Your living home address',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14.0,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      DividerWidget(),
                      SizedBox(
                        height: 16.0,
                      ),
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
                              Container(
                                width: MediaQuery.of(context).size.width / 1.30,
                                child: Text(
                                  "Add Work",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                'Your office address',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14.0,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        offset: Offset(
                          0.7,
                          0.7,
                        ),
                      ),
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 17.0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.tealAccent[100],
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Image.asset(
                                "assets/images/taxi.png",
                                height: 70.0,
                                width: 80.0,
                              ),
                              SizedBox(
                                width: 16.0,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Car',
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      fontFamily: "Brand bold",
                                    ),
                                  ),
                                  Text(
                                    '10km',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontFamily: "Brand bold",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
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
                            Text(
                              'Cash',
                            ),
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
                      SizedBox(
                        height: 24.0,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: MaterialButton(
                          onPressed: () {},
                          color: Theme.of(context).accentColor,
                          child: Padding(
                            padding: EdgeInsets.all(17.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Request',
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white

                                  ),
                                ),
                                Icon(
                                  FontAwesomeIcons.taxi,
                                  color: Colors.white,
                                  size: 26.0,
                                )
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirection() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickupLatLng = LatLng(initialPos.latitude, initialPos.longtitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longtitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));

    var details = await ServicesMethod.getPlaceDirectionDetails(
        pickupLatLng, dropOffLatLng);

    Navigator.pop(context);
    print("This is encoded points");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodePolylinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);

    polylineCoordinates.clear();
    if (decodePolylinePointsResult.isNotEmpty) {
      decodePolylinePointsResult.forEach((PointLatLng pointLatLng) {
        polylineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
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
    if (pickupLatLng.latitude > dropOffLatLng.latitude &&
        pickupLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickupLatLng);
    } else if (pickupLatLng.latitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickupLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickupLatLng.longitude));
    } else if (pickupLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickupLatLng.longitude),
          northeast: LatLng(pickupLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickupLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

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
}
