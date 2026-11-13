import '../models/location_point.dart';
import '../models/route_result.dart';
import 'distance_calculator.dart';

/// Min-heap sederhana untuk antrean prioritas Dijkstra.
class _MinHeap {
  final List<(double, int)> _a = [];

  bool get isNotEmpty => _a.isNotEmpty;

  void push(double cost, int id) {
    _a.add((cost, id));
    var i = _a.length - 1;
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_a[p].$1 <= _a[i].$1) break;
      final t = _a[p];
      _a[p] = _a[i];
      _a[i] = t;
      i = p;
    }
  }

  (double, int) pop() {
    final top = _a.first;
    final last = _a.removeLast();
    if (_a.isNotEmpty) {
      _a[0] = last;
      var i = 0;
      while (true) {
        final l = 2 * i + 1, r = 2 * i + 2;
        var s = i;
        if (l < _a.length && _a[l].$1 < _a[s].$1) s = l;
        if (r < _a.length && _a[r].$1 < _a[s].$1) s = r;
        if (s == i) break;
        final t = _a[s];
        _a[s] = _a[i];
        _a[i] = t;
        i = s;
      }
    }
    return top;
  }
}

/// Dijkstra pada graf ruang-status.
///
/// Setiap simpul graf status = (mask, node): `mask` himpunan titik yang sudah
/// dikunjungi (bitmask), `node` titik terakhir. Sisi (mask,u) -> (mask|v, v)
/// berbobot jarak Haversine u-v. Status awal = ({P1}, P1). Status pertama yang
/// diambil dari antrean dengan mask penuh adalah rute terbuka terpendek yang
/// mengunjungi semua titik (optimal). Kompleksitas ~ O(2^N * N^2 * log).
class DijkstraRouting {
  static const int maxPoints = 12;

  static RouteResult solve(List<LocationPoint> points) {
    final n = points.length;
    if (n > maxPoints) {
      throw ArgumentError('Maksimal $maxPoints titik untuk Dijkstra status-graf.');
    }
    final latLngs = points.map((p) => p.latLng).toList();
    final d = DistanceCalculator.buildMatrix(latLngs);

    final full = (1 << n) - 1;
    final total = (1 << n) * n;
    final dist = List<double>.filled(total, double.infinity);
    final prev = List<int>.filled(total, -1);

    final startId = (1 << 0) * n + 0;
    dist[startId] = 0;
    final heap = _MinHeap()..push(0, startId);
    var endId = -1;

    while (heap.isNotEmpty) {
      final (cost, id) = heap.pop();
      if (cost > dist[id]) continue; // entri usang
      final mask = id ~/ n;
      final node = id % n;
      if (mask == full) {
        endId = id;
        break;
      }
      for (var v = 0; v < n; v++) {
        if (mask & (1 << v) != 0) continue;
        final nm = mask | (1 << v);
        final nid = nm * n + v;
        final nc = cost + d[node][v];
        if (nc < dist[nid]) {
          dist[nid] = nc;
          prev[nid] = id;
          heap.push(nc, nid);
        }
      }
    }

    final order = <int>[];
    for (var cur = endId; cur != -1; cur = prev[cur]) {
      order.add(cur % n);
    }
    final ordered = order.reversed.toList();

    return RouteResult(
      name: 'Dijkstra',
      order: ordered,
      distanceKm: DistanceCalculator.pathLength(ordered, d),
      polylinePoints: ordered.map((i) => latLngs[i]).toList(),
    );
  }
}
