import 'package:latlong2/latlong.dart' show LatLng;

/// Hasil satu algoritma rute.
class RouteResult {
  final String name;

  /// Urutan kunjungan sebagai indeks 0-based pada daftar titik.
  final List<int> order;
  final double distanceKm;
  final List<LatLng> polylinePoints;

  /// Rata-rata waktu komputasi (mikrodetik).
  final int computeMicros;

  const RouteResult({
    required this.name,
    required this.order,
    required this.distanceKm,
    required this.polylinePoints,
    this.computeMicros = 0,
  });

  RouteResult withTime(int micros) => RouteResult(
        name: name,
        order: order,
        distanceKm: distanceKm,
        polylinePoints: polylinePoints,
        computeMicros: micros,
      );

  double get computeMs => computeMicros / 1000.0;

  /// Contoh: "P1 → P3 → P2 → P4"
  String get orderText => order.map((i) => 'P${i + 1}').join(' → ');
}
