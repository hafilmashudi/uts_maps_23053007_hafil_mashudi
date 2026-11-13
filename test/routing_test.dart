import 'package:flutter_test/flutter_test.dart';
import 'package:uts_maps/models/location_point.dart';
import 'package:uts_maps/services/alternative_routing.dart';
import 'package:uts_maps/services/dijkstra_routing.dart';
import 'package:uts_maps/services/distance_calculator.dart';
import 'package:latlong2/latlong.dart' show LatLng;

void main() {
  final pts = [
    const LocationPoint(id: 1, lat: -6.2088, lng: 106.8456, label: 'Gudang'),
    const LocationPoint(id: 2, lat: -6.1805, lng: 106.8284, label: 'Hub Barat'),
    const LocationPoint(id: 3, lat: -6.1754, lng: 106.8650, label: 'Outlet Cempaka'),
    const LocationPoint(id: 4, lat: -6.2250, lng: 106.8000, label: 'Pelanggan D'),
  ];

  test('Haversine Jakarta-Bandung sekitar 116 km', () {
    final d = DistanceCalculator.haversine(LatLng(-6.2088, 106.8456), LatLng(-6.9175, 107.6191));
    expect(d, closeTo(116, 5));
  });

  test('Dijkstra <= Nearest Neighbor dan <= Sekuensial', () {
    final dij = DijkstraRouting.solve(pts);
    final nn = NearestNeighborRouting.solve(pts);
    final seq = SequentialRouting.solve(pts);
    expect(dij.distanceKm, lessThanOrEqualTo(nn.distanceKm + 1e-9));
    expect(dij.distanceKm, lessThanOrEqualTo(seq.distanceKm + 1e-9));
    expect(dij.order.first, 0);
    expect(dij.order.toSet().length, pts.length);
  });
}
