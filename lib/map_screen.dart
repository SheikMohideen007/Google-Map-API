import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_map_api/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? currPos = null;
  // LatLng initialPos = LatLng(13.13493638815026, 80.27816964628958);
  LatLng sourcePos = LatLng(13.133846049765134, 80.27779733782573);
  LatLng destinationPos = LatLng(12.98656387587339, 80.25457210156239);

  Location locationController = Location();

  final Completer<GoogleMapController> mapController =
      Completer<GoogleMapController>();

  Map<PolylineId, Polyline> polyLines = {};

  @override
  void initState() {
    super.initState();
    getlocationUpdates().then((_) => {
          getPolylinePoints().then((coordinates) {
            // print('...STARTED..$coordinates');
            //here adding a coordinates to the polylines with the id
            PolylineId polylineId = PolylineId('polyId');
            Polyline polyline = Polyline(
                polylineId: polylineId,
                color: Colors.black,
                points: coordinates,
                width: 2);
            setState(() {
              //setting the polyline
              polyLines[polylineId] = polyline;
            });
          })
        });
    print('init called');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currPos == null
          ? Center(child: Text('Loading ...'))
          : GoogleMap(
              onMapCreated: ((controller) {
                mapController.complete(controller);
              }),
              initialCameraPosition: CameraPosition(target: currPos!, zoom: 18),
              markers: {
                Marker(
                    markerId: MarkerId('currPos_id'),
                    icon: BitmapDescriptor.defaultMarker,
                    position: currPos!),
                Marker(
                    markerId: MarkerId('source_id'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(90),
                    position: sourcePos),
                Marker(
                    markerId: MarkerId('destination_id'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(30),
                    position: destinationPos)
              },
              polylines: Set<Polyline>.of(polyLines.values),
            ),
    );
  }

  getlocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionStatus;

    serviceEnabled = await locationController.serviceEnabled();
    // print('... before1..$serviceEnabled');
    if (serviceEnabled) {
      serviceEnabled = await locationController.requestService();
    } else {
      final snack =
          SnackBar(content: Text('Service is unavailable for your device'));
      return ScaffoldMessenger.of(context).showSnackBar(snack);
    }

    permissionStatus = await locationController.hasPermission();

    // print('... before2');

    if (permissionStatus == PermissionStatus.denied) {
      // print('... before');
      permissionStatus = await locationController.requestPermission();
      // print('... after');
      if (permissionStatus != PermissionStatus.granted) {
        print('...$permissionStatus');
        final snack = SnackBar(
            content: Text(
                'You rejected the permission. so you cant access the location'));
        return ScaffoldMessenger.of(context).showSnackBar(snack);
        // return;
      }
    }

    // this will get called whenever the location gets updated
    locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currPos =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          // print('position...$currPos');
          cameraToPosition(currPos!);
        });
      }
    });
  }

  // when the location changes, the camera position also need to change according to the location updates
  Future<void> cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await mapController.future;
    CameraPosition newCamerPosition = CameraPosition(target: pos, zoom: 16);
    controller.animateCamera(CameraUpdate.newCameraPosition(newCamerPosition));
  }

  // getting the polyline points and adding to the poly line coordinates
  getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
            origin: PointLatLng(sourcePos.latitude, sourcePos.longitude),
            destination:
                PointLatLng(destinationPos.latitude, destinationPos.longitude),
            mode: TravelMode.driving),
        googleApiKey: GOOGLE_API_KEY);
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    } else {
      print(result.errorMessage);
    }

    return polylineCoordinates;
  }
}
