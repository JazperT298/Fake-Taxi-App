import 'package:firebase_database/firebase_database.dart';

class History {
  String paymentMethod;
  String createdAt;
  String status;
  String fares;
  String dropOff;
  String pickup;

  History({this.paymentMethod, this.createdAt, this.status, this.fares, this.dropOff, this.pickup});

  History.fromSnapshot(DataSnapshot snapshot) {
    paymentMethod = snapshot.value["payment_method"];
    createdAt = snapshot.value["create_at"];
    status = snapshot.value["status"];
    fares = snapshot.value["fares"];
    dropOff = snapshot.value["dropoff_address"];
    pickup = snapshot.value["pickup_address"];
  }
}
