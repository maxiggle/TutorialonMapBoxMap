import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mapbox_demo/providers/map_providers.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'providers/remote_provider.dart';

String ACCESS_TOKEN = const String.fromEnvironment("PUBLIC_ACCESS_TOKEN");
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  log(ACCESS_TOKEN);
  mb.MapboxOptions.setAccessToken(ACCESS_TOKEN);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RemoteData()),
        ChangeNotifierProxyProvider<RemoteData, MapProviders>(
          create: (context) => MapProviders(),
          update: (_, remoteData, mapProvider) => mapProvider ?? MapProviders()
            ..remoteData = remoteData,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  mb.MapboxMap? mapboxMap;
  geo.Position? _currentPosition;
  mb.Position _position = mb.Position(0, 0);
  late MapProviders mapProviders;
  @override
  void initState() {
    super.initState();
    loadPermissions();
    mapProviders = Provider.of<MapProviders>(context, listen: false);
    context.read<RemoteData>().fetchRemoteData(
        'https://mocki.io/v1/22dbf638-88de-44b9-b767-7e8fc9979cc7');
  }

  Future<void> loadPermissions() async {
    final _positions = await Provider.of<MapProviders>(context, listen: false)
        .requestPermissions();
    setState(() {
      _currentPosition = _positions;
    });
  }

  void _upDateCamera(mb.MapboxMap mapboxMap) async {
    if (_currentPosition == null) {
      return;
    }
    final lngStr = _currentPosition!.longitude.toString();
    final latStr = _currentPosition!.latitude.toString();
    _position = mb.Position(num.parse(lngStr), num.parse(latStr));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: _scaffoldKey,
      title: 'Mapbox Maps Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Stack(
        children: [
          mb.MapWidget(
            onMapCreated: _onMapCreated,
            onScrollListener: (_) {
              mapProviders.setClusterAndMarker(mapboxMap, context);
            },
          ),
          Positioned(
              top: 50,
              child: ElevatedButton(
                  onPressed: () {
                    _toggleHeatMapVisibility();
                  },
                  child: const Text('Toggle HeatMap'))),
        ],
      ),
    );
  }

  void _onMapCreated(mb.MapboxMap controller) async {
    mapboxMap = controller;
    mapProviders.addLayerAndSource(controller);
    final colors = [Colors.amber, Colors.black, Colors.blue];
    int accuracyColor = 0;
    int pulsingColor = 0;
    pulsingColor++;
    pulsingColor %= colors.length;
    accuracyColor++;
    accuracyColor %= colors.length;
    await controller.location.updateSettings(
      mb.LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        showAccuracyRing: true,
        accuracyRingColor: colors[accuracyColor].value,
        accuracyRingBorderColor: colors[pulsingColor].value,
      ),
    );
  }

  bool isHeatMapVisible = true;
  void _toggleHeatMapVisibility() async {
    if (isHeatMapVisible) {
      final heatMapData = await mapProviders.generateHeatMapData(mapboxMap);
      // final decodedVal = json.decode(heatMapData);
      // final features = decodedVal['features'] as List<dynamic>;
      // final maxIntensityCount = features.map((a) {
      //   final featureType = a['type'];
      //   final intensity = a['properties']['intensity'];
      //   final intensityCoordinates =
      //       a['geometry']['coordinates'] as List<dynamic>;
      //   final intensityLong = intensityCoordinates[0] as num;
      //   final intensityLat = intensityCoordinates[1] as num;
      //   return {
      //     'type': featureType,
      //     'intensity': intensity,
      //     'intensityCoordinates': [intensityLong, intensityLat]
      //   };
      // }).toList();
      // log('message:${maxIntensityCount[0]['intensity']}');
      // log('heatMapData $heatMapData');
      await mapboxMap?.style
          .addSource(mb.GeoJsonSource(id: "heatmap-source", data: heatMapData));
      await mapboxMap?.style.addLayer(mb.HeatmapLayer(
          id: "heatmap-layer",
          sourceId: "heatmap-source",
          minZoom: 1.0,
          maxZoom: 20.0,
          heatmapWeight: 1.0,
          heatmapIntensity: 1.0,
          heatmapRadius: 20.0,
          heatmapOpacity: 0.7));
    } else {
      await mapboxMap?.style.removeStyleLayer('heatmap-layer');
      await mapboxMap?.style.removeStyleSource('heatmap-source');
    }
    setState(() {
      isHeatMapVisible = !isHeatMapVisible;
    });
  }
}
