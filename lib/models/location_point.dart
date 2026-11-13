import 'package:latlong2/latlong.dart';

/// Satu titik tujuan pengiriman.
class LocationPoint {
  final int id;
  final double lat;
  final double lng;
  final String label;

  const LocationPoint({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
  });

  LatLng get latLng => LatLng(lat, lng);
}
