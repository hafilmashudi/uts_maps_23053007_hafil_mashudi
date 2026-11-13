import 'dart:math';
import 'package:latlong2/latlong.dart' show LatLng;

/// Perhitungan jarak geodetik memakai rumus Haversine.
class DistanceCalculator {
  static const double earthRadiusKm = 6371.0;

  static double _rad(double deg) => deg * pi / 180.0;

  /// Jarak (km) antara dua koordinat.
  static double haversine(LatLng a, LatLng b) {
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final sLat = sin(dLat / 2);
    final sLon = sin(dLon / 2);
    final h = sLat * sLat +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * sLon * sLon;
    return 2 * earthRadiusKm * asin(sqrt(h));
  }

  /// Matriks jarak N x N (graf lengkap berbobot).
  static List<List<double>> buildMatrix(List<LatLng> pts) {
    final n = pts.length;
    final m = List.generate(n, (_) => List<double>.filled(n, 0));
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = haversine(pts[i], pts[j]);
        m[i][j] = d;
        m[j][i] = d;
      }
    }
    return m;
  }

  /// Total jarak sebuah urutan kunjungan (rute terbuka, tanpa kembali ke awal).
  static double pathLength(List<int> order, List<List<double>> m) {
    var total = 0.0;
    for (var i = 0; i < order.length - 1; i++) {
      total += m[order[i]][order[i + 1]];
    }
    return total;
  }
}
