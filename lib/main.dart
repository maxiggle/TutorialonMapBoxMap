import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mapbox_demo/providers/map_providers.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart' as geo;

import 'providers/remote_provider.dart';

String ACCESS_TOKEN = const String.fromEnvironment("PUBLIC_ACCESS_TOKEN");
final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  log(ACCESS_TOKEN);
  MapboxOptions.setAccessToken(ACCESS_TOKEN);
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
  MapboxMap? mapboxMap;
  geo.Position? _currentPosition;
  Position _position = Position(0, 0);
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

  void _upDateCamera(MapboxMap mapboxMap) async {
    if (_currentPosition == null) {
      return;
    }
    final lngStr = _currentPosition!.longitude.toString();
    final latStr = _currentPosition!.latitude.toString();
    _position = Position(num.parse(lngStr), num.parse(latStr));
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
      home: MapWidget(
        onMapCreated: _onMapCreated,
        onScrollListener: (_) {
          log('message');
          mapProviders.setClusterAndMarker(mapboxMap, context);
        },
      ),
    );
  }

  bool isHeatMapVisible = true;
  void _toggleHeatMapVisibility(mapboxMap) async {
    if (isHeatMapVisible) {
      await mapboxMap?.style.addLayer(mapboxMap.HeatmapLayer(
        id: "layer",
        sourceId: "heatMap",
        visibility: mapboxMap.Visibility.VISIBLE,
        minZoom: 1.0,
        maxZoom: 20.0,
        slot: mapboxMap.LayerSlot.MIDDLE,
        heatmapIntensity: 10.0,
        heatmapOpacity: 10.0,
        heatmapRadius: 10.0,
        heatmapWeight: 10.0,
      ));
    } else {
      await mapboxMap?.style.removeStyleLayer('layer');
    }
    setState(() {
      isHeatMapVisible = !isHeatMapVisible;
    });
  }

  void _onMapCreated(MapboxMap controller) async {
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
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
        showAccuracyRing: true,
        accuracyRingColor: colors[accuracyColor].value,
        accuracyRingBorderColor: colors[pulsingColor].value,
      ),
    );
  }
}
