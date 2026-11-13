Smart Logistics Routing (UTS Advanced Topics in Mobile Programming)

Aplikasi mobile Flutter untuk mengoptimalkan rute pengiriman multi-destinasi pada studi kasus Express Route Logistics. Pengguna memasukkan beberapa titik tujuan, lalu aplikasi menggambar dan membandingkan tiga rute: sekuensial (urutan input), Dijkstra, dan Nearest Neighbor.

| | |
|---|---|
| Nama | Hafil Mashudi|
| NIM | 23053007 |
| Mata Kuliah | Advanced Topics in Mobile Programming |
| Topik | Maps-Flutter & Route Optimization Algorithm |

Fitur

- Peta interaktif (OpenStreetMap via `flutter_map`, tanpa API key) dengan zoom, geser, dan tombol re-center.
- Indikator koordinat real-time di bagian atas layar: menampilkan titik tengah peta saat digeser.
- Input multi-titik (3–10 titik) dengan dua metode:
  - Metode A: form Latitude, Longitude, dan Keterangan Lokasi, lalu tombol Tambah Titik (dengan validasi rentang koordinat).
  - Metode B: ketuk peta, lalu isi keterangan pada dialog pop-up.
- Marker bernomor: titik awal berwarna hijau, titik tujuan merah. Ketuk marker untuk dialog informasi (nama, Lat, Lng, dan opsi hapus).
- Daftar titik di bawah peta, dengan tombol hapus tiap titik.
- Tiga tombol rute (polyline):
  1. Sekuensial (oranye): P1 → P2 → ... → Pn sesuai urutan input.
  2. Dijkstra (biru tebal): rute terbuka terpendek yang melewati semua titik.
  3. Nearest Neighbor (ungu): rute heuristik greedy.
- Panel komparasi: total titik, jarak dan urutan tiap algoritma, tabel perbandingan (jarak, waktu komputasi, selisih terhadap terbaik), diagram batang, peringkat, serta penghematan jarak dan persentase efisiensi. Tersedia juga tombol Bandingkan Semua Algoritma dan Reset Semua Rute.

Teknologi

- Flutter / Dart 3
- [`flutter_map`](https://pub.dev/packages/flutter_map) 7.x dan [`latlong2`](https://pub.dev/packages/latlong2)
- Tile OpenStreetMap

Struktur Proyek


uts_maps_23053019_muhammaddimasafifudin/
├── lib/
│   ├── models/
│   │   ├── location_point.dart        # model titik (id, lat, lng, keterangan)
│   │   └── route_result.dart          # hasil rute (urutan, jarak, polyline, waktu komputasi)
│   ├── services/
│   │   ├── distance_calculator.dart   # rumus Haversine + matriks jarak
│   │   ├── dijkstra_routing.dart      # Dijkstra pada graf ruang-status
│   │   └── alternative_routing.dart   # rute sekuensial + Nearest Neighbor
│   ├── widgets/
│   │   ├── map_view_widget.dart       # peta, marker, polyline
│   │   ├── coordinate_input_form.dart # form input + validasi
│   │   └── route_summary_card.dart    # panel komparasi
│   └── main.dart                      # entry point + state halaman utama
├── test/routing_test.dart             # unit test Haversine & algoritma
├── docs/screenshots/                  # bukti pengujian TC-01 s/d TC-05
├── pubspec.yaml
└── README.md

Membangun APK lewat GitHub Actions: repositori ini dibangun menjadi APK melalui GitHub Actions. Setelah workflow selesai, unduh berkas `app-release.apk` dari bagian Artifacts pada halaman run, lalu pasang di smartphone Android (aktifkan Install from unknown sources).

> Android: pastikan `android/app/src/main/AndroidManifest.xml` memuat `<uses-permission android:name="android.permission.INTERNET"/>` agar tile peta dapat dimuat pada build release.

Penjelasan Algoritma

1. Jarak antar titik: Formula Haversine

$$d = 2R \cdot \arcsin\left(\sqrt{\sin^2\left(\frac{\Delta\text{lat}}{2}\right) + \cos(\text{lat}_1)\cos(\text{lat}_2)\sin^2\left(\frac{\Delta\text{lon}}{2}\right)}\right)$$

dengan $R = 6371$ km dan $\Delta\text{lat}$, $\Delta\text{lon}$ dalam radian. Jarak ini menjadi bobot sisi pada graf lengkap antar titik (jarak garis lurus, bukan jarak jalan raya

2. Algoritma Dijkstra (graf ruang-status)

Dijkstra klasik mencari jalur terpendek antara dua simpul lewat relaksasi sisi: jika $d(u) + w(u,v) < d(v)$ maka $d(v) = d(u) + w(u,v)$. Pada graf lengkap berbobot jarak garis lurus, jalur terpendek dua titik selalu sisi langsungnya, sehingga Dijkstra klasik tidak dapat mengoptimalkan urutan kunjungan. Karena itu Dijkstra diterapkan pada graf ruang-status:

- Simpul = $(S, u)$: $S$ himpunan titik yang sudah dikunjungi (bitmask), $u$ titik terakhir.
- Sisi $(S, u) \to (S + \{v\}, v)$ untuk $v \notin S$, berbobot $d(u, v)$.
- Simpul awal $(\{P_1\}, P_1)$. Antrean prioritas (min-heap) selalu mengeluarkan status dengan jarak terkecil.
- Status pertama dengan $S$ berisi semua titik adalah rute terbuka terpendek yang melewati seluruh titik. Urutan diperoleh dengan menelusuri pointer `prev`.

Kompleksitas $\approx O(2^N \cdot N^2 \log(2^N N))$, praktis untuk $N \le 10$ (batas aplikasi) hingga sekitar 12. Hasilnya optimal karena bobot tidak negatif.

3. Algoritma alternatif: Nearest Neighbor (Greedy TSP)

Dari $P_1$, selalu pindah ke titik belum dikunjungi yang jarak Haversine-nya paling dekat dari posisi saat ini, sampai semua titik terkunjungi.

- Kompleksitas $O(N^2)$: sangat cepat dan mudah diimplementasikan di perangkat mobile.
- Tidak menjamin optimal: pilihan terbaik per langkah dapat menyisakan titik jauh di akhir, sehingga jaraknya $\ge$ hasil Dijkstra.

4. Efisiensi penghematan

$$\text{Penghematan} = J_{\text{sekuensial}} - J_{\text{terpendek}}, \qquad \text{Efisiensi} = \frac{J_{\text{sekuensial}} - J_{\text{terpendek}}}{J_{\text{sekuensial}}} \times 100\%$$

Hasil Pengujian

Pengujian dilakukan pada smartphone Android (APK dari GitHub Actions) dengan 6 titik di Jawa Timur: Surabaya (P1, titik awal), Pasuruan, Jombang, Lamongan, Bojonegoro, dan titik 6 di sekitar Malang.

| Algoritma | Urutan | Jarak (km) | Waktu (ms) | Selisih vs terbaik |
|---|---|---:|---:|---:|
| Sekuensial | P1 → P2 → P3 → P4 → P5 → P6 | 345,09 | 0,002 | +85,37 km |
| Dijkstra | P1 → P2 → P6 → P3 → P4 → P5 | 259,72 | 0,046 | Terbaik |
| Nearest Neighbor | P1 → P4 → P5 → P3 → P6 → P2 | 260,05 | 0,007 | +0,33 km |

Penghematan jarak (Dijkstra vs sekuensial): 85,37 km (efisiensi 24,7%). Nearest Neighbor hanya 0,33 km (0,1%) lebih panjang dari Dijkstra pada data ini, tetapi sekitar 6,6x lebih cepat dihitung.

- Jarak memakai Haversine (garis lurus), bukan jarak tempuh lewat jalan; polyline digambar lurus antar titik.
- Dijkstra pada graf ruang-status tumbuh eksponensial terhadap jumlah titik, sehingga aplikasi membatasi 3–10 titik.
