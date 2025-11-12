import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_selection.dart';

class LocationPickerPageArgs {
  final int rollcallId;

  const LocationPickerPageArgs({required this.rollcallId});
}

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, required this.args});

  final LocationPickerPageArgs args;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _campusLatLng = LatLng(25.2854, 110.3290);
  final MapController _mapController = MapController();
  LatLng _selectedPosition = _campusLatLng;
  double _selectedAccuracy = 30;
  String _statusText = '正在获取位置...';
  String _addressText = '';
  bool _isLoading = true;
  bool _permissionDenied = false;
  bool _mapReady = false;
  double _currentZoom = 16;
  Timer? _reverseGeocodeDebounce;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _reverseGeocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _statusText = '正在获取位置...';
      _permissionDenied = false;
    });

    final hasPermission = await _ensurePermission();
    if (!hasPermission) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _statusText = '无法获取定位权限，请手动拖动地图选择位置';
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateSelection(
        LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        fetchAddress: true,
      );
      setState(() {
        _isLoading = false;
        _statusText = '已定位到当前位置，可拖动地图微调';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusText = '定位失败，已回退至默认位置，可手动选择';
      });
      _updateSelection(_campusLatLng, fetchAddress: false);
    }
  }

  Future<bool> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusText = '定位服务未开启，请打开定位或手动选择位置';
      });
    }
    return true;
  }

  void _onMapMoveEnd(MapCamera camera) {
    setState(() {
      _currentZoom = camera.zoom;
      _selectedPosition = camera.center;
    });
    _scheduleReverseGeocode(camera.center);
  }

  void _scheduleReverseGeocode(LatLng target) {
    _reverseGeocodeDebounce?.cancel();
    _reverseGeocodeDebounce = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode(target);
    });
  }

  Future<void> _reverseGeocode(LatLng target) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (!mounted) return;
      if (placemarks.isEmpty) {
        setState(() {
          _addressText = _formatCoordinateText(target);
        });
        return;
      }
      final place = placemarks.first;
      final buffer = StringBuffer();
      if (place.administrativeArea?.isNotEmpty == true) {
        buffer.write(place.administrativeArea);
      }
      if (place.locality?.isNotEmpty == true) {
        if (buffer.isNotEmpty) buffer.write(' · ');
        buffer.write(place.locality);
      }
      if (place.street?.isNotEmpty == true) {
        if (buffer.isNotEmpty) buffer.write(' · ');
        buffer.write(place.street);
      }
      final formatted = buffer.isEmpty
          ? _formatCoordinateText(target)
          : buffer.toString();
      setState(() {
        _addressText = formatted;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressText = _formatCoordinateText(target);
      });
    }
  }

  void _updateSelection(
    LatLng target, {
    double? accuracy,
    bool fetchAddress = true,
  }) {
    setState(() {
      _selectedPosition = target;
      _selectedAccuracy = accuracy ?? _selectedAccuracy;
    });
    if (_mapReady) {
      _mapController.move(target, _currentZoom);
    }
    if (fetchAddress) {
      _scheduleReverseGeocode(target);
    } else {
      setState(() {
        _addressText = _formatCoordinateText(target);
      });
    }
  }

  Future<void> _recenterToCurrent() async {
    setState(() {
      _statusText = '正在获取当前位置...';
      _isLoading = true;
    });
    await _initLocation();
  }

  void _confirmSelection() {
    const crs = CoordinateSystem.wgs84;
    final result = LocationSelectionResult(
      latitude: _selectedPosition.latitude,
      longitude: _selectedPosition.longitude,
      accuracy: _selectedAccuracy,
      crs: crs,
    );
    Get.back(result: result);
  }

  String _formatCoordinateText(LatLng target) =>
      '${target.latitude.toStringAsFixed(6)}, ${target.longitude.toStringAsFixed(6)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择签到位置'),
        actions: [
          IconButton(
            tooltip: '回到当前位置',
            icon: const Icon(Icons.my_location_outlined),
            onPressed: _permissionDenied ? null : _recenterToCurrent,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition,
                    initialZoom: _currentZoom,
                    onMapReady: () => setState(() => _mapReady = true),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapEvent: (event) {
                      if (event is MapEventMoveEnd) {
                        _onMapMoveEnd(event.camera);
                      } else if (event is MapEventMove) {
                        _currentZoom = event.camera.zoom;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.verygoodapp.tronclass',
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Center(
                    child: Icon(Icons.place, size: 48, color: Colors.redAccent),
                  ),
                ),
                if (_isLoading)
                  const Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusText,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _addressText.isEmpty
                      ? _formatCoordinateText(_selectedPosition)
                      : _addressText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '提示：如果您位于中国大陆，可能需要科学上网以加载地图瓦片。',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _permissionDenied
                            ? null
                            : _recenterToCurrent,
                        icon: const Icon(Icons.gps_fixed),
                        label: const Text('使用当前位置'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _confirmSelection,
                        child: const Text('确认位置'),
                      ),
                    ),
                  ],
                ),
                if (_permissionDenied)
                  TextButton(
                    onPressed: openAppSettings,
                    child: const Text('前往系统设置开启位置权限'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
