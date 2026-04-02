import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class AddressPicker extends StatefulWidget {
  const AddressPicker({super.key});

  @override
  State<AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  // Default: Ahmedabad (Updates to User GPS)
  LatLng pickedLocation = const LatLng(23.0225, 72.5714); 
  String pickedAddress = "Locating your position...";
  final MapController _mapController = MapController();
  bool isDragging = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // GPS: Find User
  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition();
    LatLng current = LatLng(position.latitude, position.longitude);
    
    // Zoom 17 is perfect for street level
    _mapController.move(current, 17);
    setState(() => pickedLocation = current);
    _getAddress(current);
  }

  // Convert Coordinates to Readable Text
  Future<void> _getAddress(LatLng loc) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        setState(() {
          pickedAddress = "${p.name}, ${p.subLocality}, ${p.locality}, ${p.postalCode}";
          isDragging = false;
        });
      }
    } catch (e) {
      setState(() { pickedAddress = "Searching..."; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.brown),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // THE NEW MAP: CARTODB VOYAGER (High Res + High Zoom)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: pickedLocation,
              initialZoom: 17,
              // LIMITS: Prevents the "Data not available" error
              minZoom: 3,
              maxZoom: 19, 
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    pickedLocation = pos.center!;
                    isDragging = true;
                  });
                }
              },
              onPointerUp: (event, point) => _getAddress(pickedLocation),
            ),
            children: [
              TileLayer(
                // PREMIUM VOYAGER STYLE (Stable & Free)
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.sipandsip.coffee',
              ),
            ],
          ),

          // MODERN CENTER PIN
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 45),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.brown,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Text(
                      isDragging ? "Locating..." : "Deliver Here",
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.location_on, color: Colors.brown, size: 50),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), shape: BoxShape.circle)),
                ],
              ),
            ),
          ),

          // FIND MY LOCATION BUTTON
          Positioned(
            bottom: 240, right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              mini: true,
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location, color: Colors.brown),
            ),
          ),

          // PREMIUM BOTTOM CARD
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: const Color(0xFFF5E6D3), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.navigation_rounded, color: Colors.brown, size: 22),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DELIVERY ADDRESS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            Text(
                              isDragging ? "Moving map..." : pickedAddress,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.brown, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      onPressed: isDragging ? null : () => Navigator.pop(context, pickedAddress),
                      child: const Text("Confirm & Continue", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}