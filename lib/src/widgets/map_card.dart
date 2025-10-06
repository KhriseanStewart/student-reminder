import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'full_map_screen.dart'; // 👈 full screen map

enum MapLoadState { loading, ready, error }

class MapStatus {
  const MapStatus._(this.state, {this.position, this.error});

  const MapStatus.loading() : this._(MapLoadState.loading);
  const MapStatus.ready(Position position)
      : this._(MapLoadState.ready, position: position);
  const MapStatus.error(String message)
      : this._(MapLoadState.error, error: message);

  final MapLoadState state;
  final Position? position;
  final String? error;
}

class MapCard extends StatefulWidget {
  final ValueChanged<MapStatus>? onStatusChanged;
  final LatLng? fixedPosition;

  const MapCard({super.key, this.onStatusChanged, this.fixedPosition});

  @override
  State<MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  Set<Marker> _markers = {};

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(18.0179, -76.8099), // Kingston, JA fallback
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _emitStatus(const MapStatus.loading());

    if (widget.fixedPosition != null) {
      _setFixedMarker(widget.fixedPosition!);
      _isLoading = false;
    } else {
      _initializeLocation();
    }
  }

  void _setFixedMarker(LatLng pos) {
    _markers = {
      Marker(
        markerId: const MarkerId('fixed_location'),
        position: pos,
        infoWindow: const InfoWindow(title: 'Attendance Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.fixedPosition == null) {
      _initializeLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final hasPermission = await _requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission is required.';
          _isLoading = false;
        });
        _emitStatus(const MapStatus.error('Permission denied'));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      _emitStatus(MapStatus.ready(position));
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
      _emitStatus(MapStatus.error(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (widget.fixedPosition != null) {
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(widget.fixedPosition!, 15),
      );
    } else if (_currentPosition != null) {
      controller.moveCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        ),
      );
    }
  }

  void _emitStatus(MapStatus status) {
    widget.onStatusChanged?.call(status);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: widget.fixedPosition != null
                ? CameraPosition(target: widget.fixedPosition!, zoom: 15)
                : _defaultPosition,
            markers: _markers,
            myLocationEnabled: widget.fixedPosition == null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            liteModeEnabled: true,
          ),

          // Tap → open full screen map
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FullMapScreen(),
                    ),
                  );
                },
              ),
            ),
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          if (_errorMessage != null && !_isLoading)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}