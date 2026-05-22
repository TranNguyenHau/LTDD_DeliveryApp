import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class MapPickerResult {
  final String address;
  final double lat;
  final double lng;

  MapPickerResult({
    required this.address,
    required this.lat,
    required this.lng,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late MapController _mapController;

  LatLng _currentCenter = const LatLng(10.762622, 106.660172);

  String _currentAddress = "Đang lấy địa chỉ...";
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();

    _mapController = MapController();

    if (widget.initialLat != null && widget.initialLng != null) {
      _currentCenter = LatLng(
        widget.initialLat!,
        widget.initialLng!,
      );
    }

    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra GPS
    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng bật GPS'),
          ),
        );
      }
      return;
    }

    // Kiểm tra quyền
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn đã từ chối quyền vị trí'),
          ),
        );
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hãy cấp quyền vị trí trong cài đặt'),
          ),
        );
      }
      return;
    }

    // Lấy vị trí hiện tại
    final pos = await Geolocator.getCurrentPosition();

    _moveTo(
      LatLng(pos.latitude, pos.longitude),
    );
  }

  void _moveTo(LatLng pos) {
    if (!mounted) return;

    // Đợi map build xong mới gọi move
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(pos, 15);
      } catch (e) {
        // Controller đã dispose, bỏ qua
      }
    });

    setState(() {
      _currentCenter = pos;
    });

    _getAddress(pos);
  }

  Future<void> _getAddress(LatLng pos) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        setState(() {
          _currentAddress =
          "${place.street}, "
              "${place.subLocality}, "
              "${place.locality}, "
              "${place.administrativeArea}";
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Không xác định được địa chỉ";
      });
    } finally {
      setState(() {
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn địa chỉ giao hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,

              // Khi kéo map
              onPositionChanged: (camera, hasGesture) {
                if (camera.center != null) {
                  setState(() {
                    _currentCenter = camera.center!;
                  });
                }
              },

              // Khi dừng kéo map
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _getAddress(_currentCenter);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                // FIX LỖI 403
                userAgentPackageName:
                'com.example.food_app',
              ),

              CurrentLocationLayer(),
            ],
          ),

          // Marker giữa map
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),

          // Bottom card
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isLoadingAddress
                        ? 'Đang tìm địa chỉ...'
                        : _currentAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MapPickerResult(
                            address: _currentAddress,
                            lat: _currentCenter.latitude,
                            lng: _currentCenter.longitude,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Xác nhận địa chỉ',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}