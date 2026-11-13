import 'package:flutter/material.dart';

/// Form input Metode A: Latitude, Longitude, Keterangan.
class CoordinateInputForm extends StatefulWidget {
  /// Mengembalikan pesan error (String) jika gagal, atau null jika sukses.
  final String? Function(double lat, double lng, String label) onAdd;

  const CoordinateInputForm({super.key, required this.onAdd});

  @override
  State<CoordinateInputForm> createState() => _CoordinateInputFormState();
}

class _CoordinateInputFormState extends State<CoordinateInputForm> {
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _label = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _lat.dispose();
    _lng.dispose();
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    final lat = double.tryParse(_lat.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lng.text.trim().replaceAll(',', '.'));
    final label = _label.text.trim();

    String? err;
    if (lat == null || lng == null) {
      err = 'Latitude/Longitude harus berupa angka.';
    } else if (lat < -90 || lat > 90) {
      err = 'Latitude harus di antara -90 dan 90.';
    } else if (lng < -180 || lng > 180) {
      err = 'Longitude harus di antara -180 dan 180.';
    } else if (label.isEmpty) {
      err = 'Keterangan lokasi wajib diisi.';
    } else {
      err = widget.onAdd(lat, lng, label);
    }

    setState(() => _error = err);
    if (err == null) {
      _lat.clear();
      _lng.clear();
      _label.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const numKb = TextInputType.numberWithOptions(decimal: true, signed: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _lat,
                keyboardType: numKb,
                decoration: const InputDecoration(
                    labelText: 'Latitude', isDense: true, border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _lng,
                keyboardType: numKb,
                decoration: const InputDecoration(
                    labelText: 'Longitude', isDense: true, border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _label,
          decoration: const InputDecoration(
              labelText: 'Keterangan Lokasi', isDense: true, border: OutlineInputBorder()),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Tambah Titik'),
          ),
        ),
      ],
    );
  }
}
