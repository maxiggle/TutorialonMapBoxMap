import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_demo/models/airpot_model.dart';
import 'package:mapbox_demo/providers/remote_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'dart:io' show Platform;
import 'package:screenshot/screenshot.dart';

class MapProviders extends ChangeNotifier {
  //Requesting for user permission and current device location

  MapProviders({this.remoteData});
  RemoteData? remoteData;
  set setPosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }

  Position? _currentPosition;
  Future<Position> requestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    AndroidSettings? settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    } else if (Platform.isIOS) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    final position =
        await Geolocator.getCurrentPosition(locationSettings: settings);
    setPosition = position;
    log('Current position: ${position.longitude}, ${position.latitude}');
    return position;
  }

//add source and layer
  Future<void> addLayerAndSource(mp.MapboxMap mapboxMap) async {
    await mapboxMap.style.styleSourceExists("earthquakes").then((value) async {
      if (!value) {
        var source = await rootBundle.loadString('assets/map_layer.json');
        mapboxMap.style.addStyleSource("earthquakes", source);
      }
    });
    await mapboxMap.style.styleLayerExists("clusters").then((value) async {
      if (!value) {
        var layer = await rootBundle.loadString('assets/cluster_layer.json');
        mapboxMap.style.addStyleLayer(layer, null);

        var clusterCountLayer =
            await rootBundle.loadString('assets/cluster_count.json');
        mapboxMap.style.addStyleLayer(clusterCountLayer, null);

        var unclusteredLayer =
            await rootBundle.loadString('assets/unclustered_count.json');
        mapboxMap.style.addStyleLayer(unclusteredLayer, null);
      }
    });
  }

  void setClusterAndMarker(
      mp.MapboxMap? mapboxMap, BuildContext context) async {
    final val = await mapboxMap?.querySourceFeatures(
        "earthquakes",
        mp.SourceQueryOptions(
          filter: "point_count",
        ));
    final positions = val?.map(
      (feature) {
        final featureMap = feature?.queriedFeature.feature;
        final geometry = featureMap?['geometry'] as Map?;
        final coordinates = geometry?['coordinates'] as List?;
        final properties = featureMap?['properties'] as Map?;
        final code = properties?['code'] as String?;
        return CustomPositions(
            lat: coordinates?[1], lon: coordinates?[0], code: code);
      },
    );
    final placesAtrr = positions?.map((e) => e.code ?? "").toSet();
    final List<AirPorts> places = [];
    final remotePlaces = remoteData?.getRemoteData;
    placesAtrr?.forEach((val) {
      final List<AirPorts> matchingAirports = remotePlaces?.where((e) {
            log('e.code: ${e.code}');
            return e.code == val;
          }).toList() ??
          [];
      if (matchingAirports.isNotEmpty) {
        for (final place in matchingAirports) {
          places.add(place);
        }
      }
    });
    addMarkers(places, mapboxMap);
  }

  void addMarkers(List<AirPorts> places, mp.MapboxMap? mapboxMap) async {
    await mapboxMap?.annotations
        .createPointAnnotationManager()
        .then((value) async {
      var options = <mp.PointAnnotationOptions>[];
      for (var i = 0; i < places.length; i++) {
        final position = mp.Position(
          num.parse(places[i].lon),
          num.parse(places[i].lat),
        );
        final image = places[i].thumbImage;
        ScreenshotController screenshotController = ScreenshotController();
        final byte = await screenshotController
            .captureFromWidget(AnnotationCard(url: image));
        options.add(
          mp.PointAnnotationOptions(
            geometry: mp.Point(coordinates: position),
            image: byte,
          ),
        );
      }
      value.createMulti(options);
      value.addOnPointAnnotationClickListener(
          AnnotationClickListener(places, mapboxMap));
    });
  }

  var feature = {
    "id": 1249,
    "properties": {
      "point_count_abbreviated": "10",
      "cluster_id": 1249,
      "cluster": true,
      "point_count": 10
    },
    "geometry": {
      "type": "Point",
      "coordinates": [-29.794921875, 59.220934076150456]
    },
    "type": "Feature"
  };
}

class CustomPositions {
  final num? lat;
  final num? lon;
  final String? code;
  CustomPositions({required this.lat, required this.lon, this.code});

  @override
  String toString() => 'CustomPositions(lat: $lat, lon: $lon, codes: $code)';
}

class AnnotationCard extends StatelessWidget {
  const AnnotationCard({super.key, required this.url});
  final String url;

  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        // color: Colors.transparent,
      ),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10), child: Image.network(url)),
    );
  }
}

class AnnotationClickListener extends mp.OnPointAnnotationClickListener {
  final List<AirPorts> places;
  final mp.MapboxMap? mapboxMap;

  AnnotationClickListener(this.places, this.mapboxMap);
  @override
  void onPointAnnotationClick(mp.PointAnnotation annotation) {
    handleAnnotationClick(annotation);
  }

  void handleAnnotationClick(mp.PointAnnotation annotation) {
    log('handleAnnotationClick');
  }
}
