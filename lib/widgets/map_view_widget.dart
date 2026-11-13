import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/location_point.dart';

class MapViewWidget extends StatelessWidget {
  final MapController controller;
  final LatLng initialCenter;
  final List<LocationPoint> points;
  final List<Polyline> polylines;
  final void Function(LatLng) onMapTap;
  final void Function(LocationPoint) onMarkerTap;
  final void Function(LatLng) onCenterChanged;

  const MapViewWidget({
    super.key,
    required this.controller,
    required this.initialCenter,
    required this.points,
    required this.polylines,
    required this.onMapTap,
    required this.onMarkerTap,
    required this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 12,
        onTap: (_, latLng) => onMapTap(latLng),
        onPositionChanged: (camera, _) => onCenterChanged(camera.center),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.uts_maps',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(
          markers: [
            for (var i = 0; i < points.length; i++)
              Marker(
                point: points[i].latLng,
                width: 44,
                height: 52,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => onMarkerTap(points[i]),
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48,
                        // Titik awal hijau, tujuan merah.
                        color: i == 0 ? Colors.green : Colors.red,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 9),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
