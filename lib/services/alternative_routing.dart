import '../models/location_point.dart';
import '../models/route_result.dart';
import 'distance_calculator.dart';

/// Rute sekuensial P1 -> P2 -> ... -> Pn (sesuai urutan input).
class SequentialRouting {
  static RouteResult solve(List<LocationPoint> points) {
    final latLngs = points.map((p) => p.latLng).toList();
    final d = DistanceCalculator.buildMatrix(latLngs);
    final order = List<int>.generate(points.length, (i) => i);
    return RouteResult(
      name: 'Sekuensial',
      order: order,
      distanceKm: DistanceCalculator.pathLength(order, d),
      polylinePoints: latLngs,
    );
  }
}

/// Algoritma alternatif: Greedy Nearest Neighbor.
/// Mulai di P1, lalu selalu pindah ke titik belum dikunjungi yang terdekat.
/// Kompleksitas O(N^2), cepat tetapi tidak menjamin optimal.
class NearestNeighborRouting {
  static RouteResult solve(List<LocationPoint> points) {
    final n = points.length;
    final latLngs = points.map((p) => p.latLng).toList();
    final d = DistanceCalculator.buildMatrix(latLngs);

    final visited = List<bool>.filled(n, false);
    final order = <int>[0];
    visited[0] = true;

    while (order.length < n) {
      final cur = order.last;
      var best = -1;
      var bestDist = double.infinity;
      for (var j = 0; j < n; j++) {
        if (!visited[j] && d[cur][j] < bestDist) {
          bestDist = d[cur][j];
          best = j;
        }
      }
      visited[best] = true;
      order.add(best);
    }

    return RouteResult(
      name: 'Nearest Neighbor',
      order: order,
      distanceKm: DistanceCalculator.pathLength(order, d),
      polylinePoints: order.map((i) => latLngs[i]).toList(),
    );
  }
}
