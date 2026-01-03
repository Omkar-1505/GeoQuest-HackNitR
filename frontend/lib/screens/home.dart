// ignore_for_file: unused_element, unused_field, unused_local_variable

import 'package:flutter/material.dart';
import 'package:frontend/screens/cameraScreen.dart';
import 'package:frontend/screens/imagePreviewScreen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraPosition? _initialCameraPosition;
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  // Go to current loacation of user
  Future<void> _goToCurrentLocation() async {
    // fall back
    if (_mapController == null) return;

    final location = _currentLocation ?? await getCurrentLocation();
    _currentLocation = location;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: 19),
      ),
    );
  }

  // Load the lacation of user
  Future<void> _loadLocations() async {
    try {
      final location = await getCurrentLocation();
      setState(() {
        _currentLocation = location;
        _initialCameraPosition = CameraPosition(target: location, zoom: 15);
      });
    } catch (e) {}
  }

  // Opening camera function
  Future<void> openCamera(BuildContext context) async {
    final imagePAth = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (imagePAth == null || _currentLocation == null) return;

    final prefs = await SharedPreferences.getInstance();

    // Save Image path in local device storage
    final images = prefs.getStringList('images') ?? [];
    images.insert(0, imagePAth);
    await prefs.setStringList('images', images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

// LOCATION HELPER
Future<LatLng> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception('Location services disabled');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw Exception('Location permission denied forever');
  }

  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return LatLng(position.latitude, position.longitude);
}
