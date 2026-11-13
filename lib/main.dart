import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'models/location_point.dart';
import 'models/route_result.dart';
import 'services/alternative_routing.dart';
import 'services/dijkstra_routing.dart';
import 'widgets/coordinate_input_form.dart';
import 'widgets/map_view_widget.dart';
import 'widgets/route_summary_card.dart';

void main() => runApp(const SmartLogisticsApp());

class SmartLogisticsApp extends StatelessWidget {
  const SmartLogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Logistics Routing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _minPoints = 3;
  static const int _maxPoints = 10;
  static final LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  final MapController _mapController = MapController();
  final ValueNotifier<LatLng> _center = ValueNotifier(_defaultCenter);
  final List<LocationPoint> _points = [];
  int _nextId = 1;

  RouteResult? _seq;
  RouteResult? _dij;
  RouteResult? _alt;

  @override
  void dispose() {
    _center.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _clearRoutes() {
    _seq = null;
    _dij = null;
    _alt = null;
  }

  /// Dipakai Metode A (form) dan Metode B (tap peta).
  String? _addPoint(double lat, double lng, String label) {
    if (_points.length >= _maxPoints) {
      return 'Maksimal $_maxPoints titik.';
    }
    setState(() {
      _points.add(LocationPoint(id: _nextId++, lat: lat, lng: lng, label: label));
      _clearRoutes(); // data berubah -> hasil lama tidak valid
    });
    return null;
  }

  void _removePoint(LocationPoint p) {
    setState(() {
      _points.removeWhere((e) => e.id == p.id);
      _clearRoutes();
    });
  }

  Future<void> _onMapTap(LatLng latLng) async {
    if (_points.length >= _maxPoints) {
      _toast('Maksimal $_maxPoints titik.');
      return;
    }
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keterangan Lokasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'mis. Gudang Sentral'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (label != null && label.isNotEmpty) {
      _addPoint(latLng.latitude, latLng.longitude, label);
    }
  }

  /// InfoWindow: dialog saat marker diketuk.
  void _onMarkerTap(LocationPoint p) {
    final idx = _points.indexWhere((e) => e.id == p.id) + 1;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('P$idx — ${p.label}'),
        content: Text('Lat: ${p.lat.toStringAsFixed(6)}\nLng: ${p.lng.toStringAsFixed(6)}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removePoint(p);
            },
            child: const Text('Hapus'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  bool _ensureEnough() {
    if (_points.length < _minPoints) {
      _toast('Minimal $_minPoints titik diperlukan (saat ini ${_points.length}).');
      return false;
    }
    return true;
  }

  /// Ukur waktu komputasi: rata-rata dari beberapa kali eksekusi.
  RouteResult _timed(RouteResult Function() f, {int runs = 20}) {
    final sw = Stopwatch()..start();
    var r = f();
    for (var i = 1; i < runs; i++) {
      r = f();
    }
    sw.stop();
    return r.withTime(sw.elapsedMicroseconds ~/ runs);
  }

  void _runSequential() {
    if (!_ensureEnough()) return;
    setState(() => _seq = _timed(() => SequentialRouting.solve(_points)));
  }

  void _runDijkstra() {
    if (!_ensureEnough()) return;
    setState(() => _dij = _timed(() => DijkstraRouting.solve(_points)));
  }

  void _runAlternative() {
    if (!_ensureEnough()) return;
    setState(() => _alt = _timed(() => NearestNeighborRouting.solve(_points)));
  }

  void _runAll() {
    if (!_ensureEnough()) return;
    setState(() {
      _seq = _timed(() => SequentialRouting.solve(_points));
      _dij = _timed(() => DijkstraRouting.solve(_points));
      _alt = _timed(() => NearestNeighborRouting.solve(_points));
    });
  }

  void _recenter() {
    if (_points.isEmpty) {
      _mapController.move(_defaultCenter, 12);
      return;
    }
    final bounds = LatLngBounds.fromPoints(_points.map((e) => e.latLng).toList());
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60), maxZoom: 16),
    );
  }

  List<Polyline> get _polylines => [
        if (_seq != null)
          Polyline(points: _seq!.polylinePoints, strokeWidth: 4, color: Colors.orange),
        if (_dij != null)
          Polyline(points: _dij!.polylinePoints, strokeWidth: 7, color: Colors.blue),
        if (_alt != null)
          Polyline(points: _alt!.polylinePoints, strokeWidth: 4, color: Colors.purple),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapViewWidget(
            controller: _mapController,
            initialCenter: _defaultCenter,
            points: _points,
            polylines: _polylines,
            onMapTap: _onMapTap,
            onMarkerTap: _onMarkerTap,
            onCenterChanged: (c) => WidgetsBinding.instance
                .addPostFrameCallback((_) => _center.value = c),
          ),
          // Indikator koordinat tengah peta (real-time saat digeser).
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                ),
                child: ValueListenableBuilder<LatLng>(
                  valueListenable: _center,
                  builder: (_, c, __) => Text(
                    'Lat: ${c.latitude.toStringAsFixed(4)} | Lng: ${c.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 56, right: 8),
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.10,
            maxChildSize: 0.9,
            builder: (context, scroll) => Material(
              elevation: 8,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                          color: Colors.grey, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const Text('Tambah Titik (form atau ketuk peta)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  CoordinateInputForm(onAdd: _addPoint),
                  const Divider(height: 24),
                  Text('Daftar Titik (${_points.length}/$_maxPoints)',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_points.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Belum ada titik. Titik pertama = titik awal (hijau).'),
                    ),
                  for (var i = 0; i < _points.length; i++)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: i == 0 ? Colors.green : Colors.red,
                        child: Text('${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text(_points[i].label),
                      subtitle: Text(
                          '(${_points[i].lat.toStringAsFixed(4)}, ${_points[i].lng.toStringAsFixed(4)})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus',
                        onPressed: () => _removePoint(_points[i]),
                      ),
                      onTap: () => _mapController.move(_points[i].latLng, 15),
                    ),
                  const Divider(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: _runSequential,
                    child: const Text('1. Rute Sesuai Urutan Input (Sekuensial)'),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _runDijkstra,
                    child: const Text('2. Rute Terpendek Dijkstra'),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                    onPressed: _runAlternative,
                    child: const Text('3. Rute Alternatif (Nearest Neighbor)'),
                  ),
                  const SizedBox(height: 6),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.teal),
                    onPressed: _runAll,
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('Bandingkan Semua Algoritma'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: () => setState(_clearRoutes),
                    child: const Text('Reset Semua Rute'),
                  ),
                  const SizedBox(height: 12),
                  RouteSummaryCard(
                    totalPoints: _points.length,
                    sequential: _seq,
                    dijkstra: _dij,
                    alternative: _alt,
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
