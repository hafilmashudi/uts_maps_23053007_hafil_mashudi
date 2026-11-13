import 'package:flutter/material.dart';
import '../models/route_result.dart';

/// Panel hasil & komparasi antar algoritma.
class RouteSummaryCard extends StatelessWidget {
  final int totalPoints;
  final RouteResult? sequential;
  final RouteResult? dijkstra;
  final RouteResult? alternative;

  const RouteSummaryCard({
    super.key,
    required this.totalPoints,
    this.sequential,
    this.dijkstra,
    this.alternative,
  });

  static const _small = TextStyle(fontSize: 12);
  static const _bold = TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  Widget _row(String title, RouteResult? r, Color color) {
    if (r == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 12, height: 12, margin: const EdgeInsets.only(top: 3, right: 8), color: color),
          Expanded(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: 'Jarak: ${r.distanceKm.toStringAsFixed(2)} km | Urutan: ${r.orderText}'),
            ])),
          ),
        ],
      ),
    );
  }

  Widget _cell(String t, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
        child: Text(t, style: (bold ? _bold : _small).copyWith(color: color)),
      );

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color, RouteResult)>[
      if (sequential != null) ('Sekuensial', Colors.orange, sequential!),
      if (dijkstra != null) ('Dijkstra', Colors.blue, dijkstra!),
      if (alternative != null) ('Nearest Neighbor', Colors.purple, alternative!),
    ];

    final children = <Widget>[
      Text('Total Titik Terdaftar: $totalPoints',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      _row('Rute Sekuensial', sequential, Colors.orange),
      _row('Rute Dijkstra', dijkstra, Colors.blue),
      _row('Rute Nearest Neighbor', alternative, Colors.purple),
    ];

    if (entries.isEmpty) {
      children.add(const Text('Belum ada rute. Tekan salah satu tombol rute.'));
    }

    if (entries.length >= 2) {
      final best = entries.map((e) => e.$3.distanceKm).reduce((a, b) => a < b ? a : b);
      final worst = entries.map((e) => e.$3.distanceKm).reduce((a, b) => a > b ? a : b);
      final ranked = [...entries]..sort((a, b) => a.$3.distanceKm.compareTo(b.$3.distanceKm));

      children.add(const Divider(height: 20));
      children.add(const Text('Komparasi Antar Algoritma',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)));
      children.add(const SizedBox(height: 6));

      // Tabel
      children.add(Table(
        columnWidths: const {
          0: FlexColumnWidth(2.4),
          1: FlexColumnWidth(1.4),
          2: FlexColumnWidth(1.4),
          3: FlexColumnWidth(1.5),
        },
        border: TableBorder.all(color: Colors.black12),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFEEF0FA)),
            children: [
              _cell('Algoritma', bold: true),
              _cell('Jarak (km)', bold: true),
              _cell('Waktu (ms)', bold: true),
              _cell('Selisih vs terbaik', bold: true),
            ],
          ),
          for (final e in entries)
            TableRow(children: [
              _cell(e.$1, bold: true, color: e.$2),
              _cell(e.$3.distanceKm.toStringAsFixed(2)),
              _cell(e.$3.computeMs.toStringAsFixed(3)),
              _cell(e.$3.distanceKm - best < 1e-9
                  ? 'Terbaik'
                  : '+${(e.$3.distanceKm - best).toStringAsFixed(2)} km'),
            ]),
        ],
      ));

      // Diagram batang jarak
      children.add(const SizedBox(height: 10));
      children.add(const Text('Perbandingan jarak', style: _bold));
      for (final e in entries) {
        final frac = worst <= 0 ? 1.0 : (e.$3.distanceKm / worst).clamp(0.05, 1.0);
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              SizedBox(width: 96, child: Text(e.$1, style: _small)),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: frac,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                          color: e.$2, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('${e.$3.distanceKm.toStringAsFixed(2)}', style: _small),
            ],
          ),
        ));
      }

      // Ranking + analisis
      children.add(const SizedBox(height: 10));
      children.add(Text(
        'Peringkat (jarak terpendek): ${ranked.map((e) => e.$1).join(' < ')}',
        style: _bold,
      ));

      final notes = <String>[];
      if (sequential != null && sequential!.distanceKm > 0) {
        final shortest = ranked.first;
        final diff = sequential!.distanceKm - shortest.$3.distanceKm;
        final pct = diff / sequential!.distanceKm * 100;
        if (diff > 1e-9) {
          notes.add('Penghematan ${shortest.$1} terhadap sekuensial: '
              '${diff.toStringAsFixed(2)} km (${pct.toStringAsFixed(1)}%).');
        } else {
          notes.add('Urutan input sudah menjadi rute terpendek (penghematan 0%).');
        }
      }
      if (dijkstra != null && alternative != null) {
        final gap = alternative!.distanceKm - dijkstra!.distanceKm;
        if (gap > 1e-9) {
          final pct = gap / dijkstra!.distanceKm * 100;
          notes.add('Nearest Neighbor ${gap.toStringAsFixed(2)} km '
              '(${pct.toStringAsFixed(1)}%) lebih panjang dari Dijkstra yang optimal, '
              'karena pilihan greedy per langkah tidak melihat dampak ke titik berikutnya.');
        } else {
          notes.add('Untuk titik-titik ini, Nearest Neighbor menghasilkan rute sama '
              'panjang dengan Dijkstra (greedy kebetulan optimal).');
        }
        if (alternative!.computeMicros > 0 && dijkstra!.computeMicros > 0) {
          final ratio = dijkstra!.computeMicros / alternative!.computeMicros;
          notes.add('Waktu komputasi: Dijkstra ${ratio.toStringAsFixed(1)}x '
              '${ratio >= 1 ? "lebih lambat" : "lebih cepat"} dari Nearest Neighbor '
              '(Dijkstra ~O(2^N·N²·log), NN O(N²)).');
        }
      }
      for (final n in notes) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('• $n', style: _small),
        ));
      }
      if (sequential == null) {
        children.add(const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text('Jalankan Rute Sekuensial untuk melihat penghematan.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
        ));
      }
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}
